# frozen_string_literal: true

require "json"
require "pathname"

require "rgame/core/aspect"
require "rgame/core/savable"
require "rgame/core/collision"
require "rgame/common/gui"
require "rgame/common/position_aspect"

module RGame
  module Common
    module EditorAspect
      include RGame::Core::Aspect

      module NewEntityModeAspect
        include RGame::Core::Aspect

        on :commit do |value|
          next unless self.edit_mode == :new_entity

          entity = self.parent.create(value) do |o|
            o.x = self.cursor[0]
            o.y = self.cursor[1]
          end

          self.reset_selection [ entity ]
        end

        def set_new_entity_edit_mode
          self.edit_mode = :new_entity
          self.create(Gui::Menu) do |o|
            o.items = RGame::Core::Entity.registry.select do |e|
              e.ancestors.include?(RGame::Common::PositionAspect) and
                e.ancestors.include?(RGame::Core::Savable)
            end
            o.x = self.cursor[0]
            o.y = self.cursor[1]
          end.focus
        end
      end

      module EditEntityModeAspect
        include RGame::Core::Aspect

        on :commit do |value|
          next unless self.edit_mode == :edit_entity

          if self.selected.empty?
            # rubocop:disable Style/RescueStandardError
            begin
              self.instance_eval(value)
            rescue
              warn $!.message
            end
            # rubocop:enable Style/RescueStandardError
          else
            self.selected.map { |e| self.collection[e] }.each do |e|
              # rubocop:disable Style/RescueStandardError
              begin
                e.instance_eval(value)
              rescue
                warn $!.message
              end
              # rubocop:enable Style/RescueStandardError
            end
          end
        end

        def set_edit_entity_edit_mode
          self.edit_mode = :edit_entity
          self.create(Gui::Input) do |o|
            o.x = self.cursor[0]
            o.y = self.cursor[1]
          end.focus
        end
      end

      module SelectionAspect
        include RGame::Core::Aspect

        attr_accessor :selected

        before :keydown do |key, mod|
          next unless self.edit_mode == :default

          case key
          when "escape"
            self.clear_selection
          when "backspace", "delete"
            self.delete_selection
          when "left", "right", "up", "down"
            self.move_selection key if mod.shift and not self.selected.empty?
          when "space"
            if mod.ctrl
              self.multi_select_cursor
            else
              self.single_select_cursor
            end
          when "tab"
            self.successor_selection(mod.shift? ? -1 : 1)
          end
        end

        on :keyrepeat do |key, mod|
          next unless self.edit_mode == :default

          case key
          when "left", "right", "up", "down"
            self.move_selection key if mod.shift and not self.selected.empty?
          when "tab"
            self.successor_selection(mod.shift? ? -1 : 1)
          end
        end

        on :keyup do |key, mod|
          next unless self.edit_mode == :default

          case key
          when "left_shift", "right_shift"
            unless mod.shift
              self.inflate_select_cursor
              self.deflate_cursor
            end
          end
        end

        on :mouseup do |x, y, button, mod|
          next unless self.edit_mode == :default

          if button == "left"
            if mod.ctrl
              self.multi_select x, y
            else
              stop! unless self.single_select x, y
            end
          end
        end

        def successor_selection direction = 1
          if selected.size > 1
            tmp = selected[0]
            selected.clear
            add_to_selection tmp
          elsif selected.size == 1
            loop do
              selected[0] = (selected[0] + direction) % @collection.size
              e = @collection[selected[0]]
              break if e.is_a?(RGame::Common::PositionAspect)
            end
          end
        end

        def clear_selection
          selected.clear
        end

        def delete_selection
          selected.map { |e| @collection[e] }.each(&:remove)
          clear_selection
        end

        def move_selection direction
          case direction
          when "left"
            selected.each { |e| @collection[e].x -= grid[0] }
          when "right"
            selected.each { |e| @collection[e].x += grid[0] }
          when "up"
            selected.each { |e| @collection[e].y -= grid[1] }
          when "down"
            selected.each { |e| @collection[e].y += grid[1] }
          end
        end

        def multi_select_cursor
          multi_select cursor[0], cursor[1]
        end

        def single_select_cursor
          single_select cursor[0], cursor[1]
        end

        def single_select x, y
          not @collection.find_index do |e|
            e.is_a?(RGame::Common::PositionAspect) and
              RGame::Core::Collision.check_point([ x, y ], e)
          end.tap do |o|
            selected.clear
            add_to_selection o
          end.nil?
        end

        def multi_select x, y
          not @collection.find_index do |e|
            e.is_a?(RGame::Common::PositionAspect) and
              RGame::Core::Collision.check_point([ x, y ], e)
          end.tap do |o|
            add_to_selection o
          end.nil?
        end

        def inflate_select_cursor
          left = self.cursor[0] + [ self.cursor_inflate[0], 0 ].min
          top = self.cursor[1] + [ self.cursor_inflate[1], 0 ].min
          w = 8 + self.cursor_inflate[0].abs
          h = 8 + self.cursor_inflate[1].abs
          right = left + w - 1
          bottom = top + h - 1

          cursor_bounds = {
            "left" => left,
            "right" => right,
            "top" => top,
            "bottom" => bottom,
          }

          @collection.each_with_index.select do |e, _|
            e.is_a? RGame::Common::PositionAspect
          end.select do |e, _|
            bounds = RGame::Core::Collision.bounds_for(e)
            RGame::Core::Collision.check_bounds(bounds, cursor_bounds)
          end.each do |_, i|
            add_to_selection i
          end
        end

        def reset_selection entities
          selected.clear
          entities.each do |e|
            index = @collection.find_index { |f| f.equal?(e) }
            add_to_selection index
          end
        end

        def copy_selection
          ents = selected.map { |e| @collection[e] }
          origin = ents.reduce([ (1.0 / 0.0), (1.0 / 0.0) ]) do |m, v|
            [ [ m[0], v.x ].min, [ m[1], v.y ].min ]
          end

          ents.map do |e|
            e.dup.tap do |o|
              o.x = cursor[0] + (e.x - origin[0])
              o.y = cursor[1] + (e.y - origin[1])
            end
          end
        end

        def add_to_selection value
          selected << value unless value.nil?
          selected.uniq!
        end
      end

      module CursorAspect
        include RGame::Core::Aspect

        attr_accessor :cursor
        attr_accessor :cursor_inflate

        before :keydown do |key, mod|
          next unless self.edit_mode == :default

          case key
          when "left", "right", "up", "down"
            if mod.shift
              self.inflate_cursor key if self.selected.empty?
            else
              self.move_cursor key
            end
          end
        end

        before :keyrepeat do |key, mod|
          next unless self.edit_mode == :default

          case key
          when "left", "right", "up", "down"
            if mod.shift
              self.inflate_cursor key if self.selected.empty?
            else
              self.move_cursor key
            end
          end
        end

        on :mouseup do |x, y, button, mod|
          next unless self.edit_mode == :default

          self.put_cursor x, y if button == "left" and not mod.ctrl
        end

        def inflate_cursor direction
          case direction
          when "left"
            cursor_inflate[0] -= grid[0]
          when "right"
            cursor_inflate[0] += grid[0]
          when "up"
            cursor_inflate[1] -= grid[1]
          when "down"
            cursor_inflate[1] += grid[1]
          end
        end

        def deflate_cursor
          self.cursor_inflate = [ 0, 0 ]
        end

        def move_cursor direction
          case direction
          when "left"
            cursor[0] -= grid[0]
          when "right"
            cursor[0] += grid[0]
          when "up"
            cursor[1] -= grid[1]
          when "down"
            cursor[1] += grid[1]
          end
        end

        def put_cursor x, y
          self.cursor[0] = (x.to_i / grid[0]) * grid[0]
          self.cursor[1] = (y.to_i / grid[1]) * grid[1]
        end
      end

      module FileSaveOpenAspect
        include RGame::Core::Aspect

        on :commit do |value|
          case self.edit_mode
          when :save
            File.write(value, JSON.pretty_generate({
              "meta" => {
                "schema" => "rgame",
              },
              "background" => self.parent.map.background,
              "width" => self.parent.map.width,
              "height" => self.parent.map.height,
              "entities" => self.parent.each.to_a.select do |e|
                e.respond_to? :savable_dump
              end.map(&:savable_dump),
            }))
          when :open
            abs_path = File.expand_path value
            self.parent.map = RGame::Core::Map.load_path abs_path
          end
        end

        before :keydown do |key, mod|
          next unless self.edit_mode == :default

          case key
          when "s"
            if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super) or
               ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
              self.set_save_edit_mode
            end
          when "o"
            if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super) or
               ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
              self.set_open_edit_mode
            end
          end
        end

        def set_save_edit_mode
          self.edit_mode = :save
          self.create(Gui::Input) do |o|
            path = Pathname.new(self.parent.map.path.to_s)
            o.text = path.relative_path_from(Pathname.new(Dir.pwd)).to_s
            o.x = self.cursor[0]
            o.y = self.cursor[1]
          end.focus
        end

        def set_open_edit_mode
          self.edit_mode = :open
          self.create(Gui::Input) do |o|
            path = Pathname.new(self.parent.map.path.to_s)
            o.text = path.relative_path_from(Pathname.new(Dir.pwd)).to_s
            o.x = self.cursor[0]
            o.y = self.cursor[1]
          end.focus
        end
      end

      class EditorState < Gui::Container
        attr_accessor :collection
        attr_accessor :edit_mode
        attr_accessor :grid
        attr_reader :gui

        include NewEntityModeAspect
        include EditEntityModeAspect
        include SelectionAspect
        include CursorAspect
        include FileSaveOpenAspect

        on :commit do |_|
          self.enable_edit_mode
        end

        before :keydown do |key, mod|
          if self.edit_mode == :default
            case key
            when "enter", "return"
              copies = self.copy_selection
              if copies.empty?
                self.set_new_entity_edit_mode
                stop!
              else
                self.parent.add_bulk copies
                self.reset_selection copies
              end
            when ";"
              self.set_edit_entity_edit_mode if mod.shift
            end
          else
            case key
            when "escape"
              self.enable_edit_mode
            end
          end
        end

        before :mouseup do |_x, _y, button, _|
          next unless self.edit_mode == :default

          self.enable_edit_mode if button == "left"
        end

        on :draw do
          next unless self.edit_mode

          self.ctx.color = 0xD602DD

          @collection.each_with_index do |e, i|
            if e.is_a? RGame::Common::PositionAspect
              if self.selected.include? i
                self.ctx.save do
                  self.ctx.color = 0x00E08E
                  self.ctx.stroke_rect e.x.to_i, e.y.to_i,
                                       e.width.to_i, e.height.to_i
                end
              else
                self.ctx.stroke_rect e.x.to_i, e.y.to_i,
                                     e.width.to_i, e.height.to_i
              end
            end
          end

          if self.edit_mode == :default
            x = self.cursor[0] + [ self.cursor_inflate[0], 0 ].min
            y = self.cursor[1] + [ self.cursor_inflate[1], 0 ].min
            w = 8 + self.cursor_inflate[0].abs
            h = 8 + self.cursor_inflate[1].abs

            self.ctx.color = 0xFFFFFF
            self.ctx.stroke_rect x, y, w, h
          end
        end

        def initialize collection, context
          super

          @collection = collection
          self.edit_mode = false
          self.selected = []
          self.cursor = [ 0, 0 ]
          self.cursor_inflate = [ 0, 0 ]
          self.grid = [ 8, 8 ]
        end

        def toggle_edit_mode
          if self.edit_mode
            self.disable_edit_mode
          else
            self.enable_edit_mode
          end
        end

        def enable_edit_mode
          self.edit_mode = :default
          self.remove_all
        end

        def disable_edit_mode
          self.edit_mode = false
          self.remove_all
        end
      end

      on :new do
        @editor_state = self.make(EditorState) do |o|
          o.collection = self.children
          o.parent = self
        end
      end

      on :keydown do |key, _|
        if key == "f1"
          @editor_state.toggle_edit_mode
          stop!
        end
      end

      before :interval do
        stop! if @editor_state.edit_mode
      end

      def last message, *args
        if @editor_state.edit_mode
          super if message.to_s == "draw"
          @editor_state.emit message, *args
        else
          super
        end
      end
    end
  end
end
