require "json"
require "pathname"

require "dungeon/core/aspect"
require "dungeon/core/savable"
require "dungeon/core/collision"
require "dungeon/common/gui"
require "dungeon/common/position_aspect"

module Dungeon
  module Common
    module EditorAspect 
      include Dungeon::Core::Aspect

      class EditorState < Gui::Container
        attr_accessor :collection
        attr_accessor :edit_mode
        attr_accessor :selected
        attr_accessor :cursor
        attr_accessor :cursor_inflate
        attr_accessor :grid
        attr_reader :gui

        on :commit do |value|
          case self.edit_mode
          when :new_entity
            entity = value.new.tap do |o|
              o.x = self.cursor[0]
              o.y = self.cursor[1]
            end
            self.parent.add entity

            self.set_selection [ entity ]
          when :edit_entity
            unless self.selected.empty?
              self.selected.map { |e| self.collection[e] }.each do |e|
                e.instance_eval(value) rescue STDERR.puts $!
              end
            else
              self.instance_eval(value) rescue STDERR.puts $!
            end
          when :save
            File.write(value, JSON.pretty_generate({
              "meta" => {
                "schema" => "dungeon",
              },
              "background" => self.parent.map.background,
              "width" => self.parent.map.width,
              "height" => self.parent.map.height,
              "entities" => self.parent.each.to_a.select do |e|
                e.respond_to? :savable_dump
              end.map { |e| e.savable_dump },
            }))
          when :open
            self.parent.map = Dungeon::Core::Map.load_file(value)
          end

          self.enable_edit_mode
        end

        before :keydown do |key,mod|
          if self.edit_mode == :default
            case key
            when "escape"
              self.clear_selection
            when "backspace", "delete"
              self.delete_selection
            when "left", "right", "up", "down"
              if mod.shift
                unless self.selected.empty?
                  self.move_selection key
                else
                  self.inflate_cursor key
                end
              else
                self.move_cursor key
              end
            when "enter", "return"
              copies = self.copy_selection
              if copies.empty?
                self.set_new_entity_edit_mode
                stop!
              else
                self.add_bulk copies
                self.set_selection copies
              end
            when "space"
              if mod.ctrl
                self.multi_select_cursor
              else
                self.single_select_cursor
              end
            when "tab"
              if mod.shift
                self.previous_selection
              else
                self.next_selection
              end
            when ";"
              if mod.shift
                self.set_edit_entity_edit_mode
              end
            when "s"
              if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.super) or
                 ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
                self.set_save_edit_mode
              end
            when "o"
              if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.super) or
                 ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
                self.set_open_edit_mode
              end
            end
          else
            case key
            when "escape"
              self.enable_edit_mode
            end
          end
        end

        on :keyrepeat do |key,mod|
          if self.edit_mode == :default
            case key
            when "left", "right", "up", "down"
              if mod.shift
                unless self.selected.empty?
                  self.move_selection key
                else
                  self.inflate_cursor key
                end
              else
                self.move_cursor key
              end
            when "tab"
              if mod.shift
                self.previous_selection
              else
                self.next_selection
              end
            end
          end
        end

        on :keyup do |key,mod|
          if self.edit_mode == :default
            case key
            when "left_shift", "right_shift"
              unless mod.shift
                self.inflate_select_cursor
                self.deflate_cursor
              end
            end
          end
        end

        on :mouseup do |x,y,button,mod|
          if self.edit_mode == :default and button == "left"
            self.enable_edit_mode
            if mod.ctrl
              self.multi_select x, y
            else
              unless self.single_select x, y
                self.put_cursor x, y
              end
            end
          end
        end

        on :draw do
          next if not self.edit_mode
          get_var("ctx").tap do |ctx|
            return if ctx.nil?
            ctx.color = 0xD602DD

            @collection.each_with_index do |e,i|
              if e.kind_of? Dungeon::Common::PositionAspect
                if self.selected.include? i
                  ctx.save do
                    ctx.color = 0x00E08E
                    ctx.stroke_rect e.x.to_i, e.y.to_i, e.width.to_i, e.height.to_i
                  end
                else 
                  ctx.stroke_rect e.x.to_i, e.y.to_i, e.width.to_i, e.height.to_i
                end
              end
            end

            if self.edit_mode == :default
              x = self.cursor[0] + [ self.cursor_inflate[0], 0 ].min
              y = self.cursor[1] + [ self.cursor_inflate[1], 0 ].min
              w = 8 + self.cursor_inflate[0].abs
              h = 8 + self.cursor_inflate[1].abs

              ctx.color = 0xFFFFFF
              ctx.stroke_rect x, y, w, h
            end
          end
        end

        def initialize collection
          super

          @collection = collection
          self.edit_mode = false
          self.selected = []
          self.cursor = [ 0, 0 ]
          self.cursor_inflate = [ 0, 0 ]
          self.grid = [ 8, 8 ]
        end

        def set_new_entity_edit_mode
          self.edit_mode = :new_entity
          Gui::Menu.new.tap do |o|
            o.items = Dungeon::Core::Entity.registry.select do |e|
              e.ancestors.include?(Dungeon::Common::PositionAspect) and
                e.ancestors.include?(Dungeon::Core::Savable)
            end
            o.x = self.cursor[0]
            o.y = self.cursor[1]
            self.add o
            o.focus
          end
        end

        def set_edit_entity_edit_mode
          self.edit_mode = :edit_entity
          Gui::Input.new.tap do |o|
            o.x = self.cursor[0]
            o.y = self.cursor[1]
            self.add o
            o.focus
          end
        end

        def set_save_edit_mode
          self.edit_mode = :save
          Gui::Input.new.tap do |o|
            path = Pathname.new(self.parent.map.path.to_s)
            o.text = Pathname.new(path.relative_path_from(Pathname.new(Dir.pwd))).to_s
            o.x = self.cursor[0]
            o.y = self.cursor[1]
            self.add o
            o.focus
          end
        end

        def set_open_edit_mode
          self.edit_mode = :open
          Gui::Input.new.tap do |o|
            path = Pathname.new(self.parent.map.path.to_s)
            o.text = Pathname.new(path.relative_path_from(Pathname.new(Dir.pwd))).to_s
            o.x = self.cursor[0]
            o.y = self.cursor[1]
            self.add o
            o.focus
          end
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

        def put_cursor x, y
          self.cursor[0] = (x.to_i / grid[0]) * grid[0]
          self.cursor[1] = (y.to_i / grid[1]) * grid[1]
        end

        def set_selection entities
          selected.clear
          entities.each do |e|
            index = @collection.find_index { |f| f.equal?(e) }
            selected << index unless index.nil?
            selected.uniq!
          end
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

        def delete_selection
          selected.map { |e| @collection[e] }.each { |e| e.remove }
          selected.clear
        end

        def copy_selection
          ents = selected.map { |e| @collection[e] }
          origin = ents.reduce([ 1.0/0.0, 1.0/0.0 ]) do |m,v|
            [ [ m[0], v.x ].min, [ m[1], v.y ].min  ]
          end

          ents.map do |e|
            e.dup.tap do |o|
              o.x = cursor[0] + (e.x - origin[0])
              o.y = cursor[1] + (e.y - origin[1])
            end
          end
        end

        def next_selection
          if selected.size > 1
            tmp = selected[0]
            selected.clear
            selected << tmp
            selected.uniq!
          elsif selected.size == 1
            loop do
              selected[0] = (selected[0] + 1) % @collection.size
              e = @collection[selected[0]]
              break if e.kind_of?(Dungeon::Common::PositionAspect)
            end
          end
        end

        def previous_selection
          if selected.size > 1
            tmp = selected[0]
            selected.clear
            selected << tmp
            selected.uniq!
          elsif selected.size == 1
            loop do
              selected[0] = (selected[0] - 1) % @collection.size
              e = @collection[selected[0]]
              break if e.kind_of?(Dungeon::Common::PositionAspect)
            end
          end
        end

        def assign_selection key, value
          selected.map { |e| @collection[e] }.each do |e|
            begin
              e.send("%s=" % key, value)
            rescue
              STDERR.puts $!.message
            end
          end
        end

        def clear_selection
          selected.clear
        end

        def single_select x, y
          not (@collection.find_index do |e|
            e.kind_of?(Dungeon::Common::PositionAspect) and
              Dungeon::Core::Collision.check_point([ x, y ], e)
          end.tap do |o|
            selected.clear
            selected << o unless o.nil?
            selected.uniq!
          end.nil?)
        end

        def multi_select x, y
          not (@collection.find_index do |e|
            e.kind_of?(Dungeon::Common::PositionAspect) and
              Dungeon::Core::Collision.check_point([ x, y ], e)
          end.tap do |o|
            selected << o unless o.nil?
            selected.uniq!
          end.nil?)
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

        def single_select_cursor
          single_select cursor[0], cursor[1]
        end

        def multi_select_cursor
          multi_select cursor[0], cursor[1]
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
          
          @collection.each_with_index.select do |e,i|
            e.kind_of?(Dungeon::Common::PositionAspect)
          end.select do |e,i|
            bounds = Dungeon::Core::Collision.bounds_for(e)
            Dungeon::Core::Collision.check_bounds(bounds, cursor_bounds)
          end.each do |e,i|
            selected << i
            selected.uniq!
          end
        end
      end

      on :new do
        @editor_state = EditorState.new.tap do |o|
          o.collection = self.children
          o.parent = self
        end
      end

      on :keydown do |key,mod|
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
