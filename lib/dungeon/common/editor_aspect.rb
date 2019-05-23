require "json"

require "dungeon/core/aspect"
require "dungeon/core/savable"
require "dungeon/common/position_aspect"

module Dungeon
  module Common
    module EditorAspect 
      include Dungeon::Core::Aspect

      class MenuState
        attr_accessor :x
        attr_accessor :y
        attr_accessor :items
        attr_accessor :cursor
        attr_accessor :padding
        attr_accessor :view_size
        attr_accessor :view_position

        def initialize x, y, items
          self.x = x
          self.y = y
          self.items = items
          self.cursor = 0
          self.padding = 4
          self.view_size = 5
          self.view_position = 0
        end

        def cursor_up
          unless @items.empty?
            @cursor = (@cursor - 1) % @items.size

            if @cursor < @view_position
              @view_position = @cursor
            elsif @cursor >= @view_position + @view_size
              @view_position = [ @items.size - @view_size, 0 ].max
            end
          end
        end

        def cursor_down
          unless @items.empty?
            @cursor = (@cursor + 1) % @items.size
            if @cursor < @view_position
              @view_position = 0
            elsif @cursor >= @view_position + @view_size
              @view_position = @cursor - @view_size + 1
            end
          end
        end

        def cursor_page_up
          unless @items.empty?
            @cursor = if @cursor == 0
              [ @items.size - 1, 0 ].max
            elsif @cursor == @view_position
              [ @cursor - @view_size + 1, 0 ].max
            else
              @view_position
            end

            if @cursor < @view_position
              @view_position = @cursor
            elsif @cursor >= @view_position + @view_size
              @view_position = [ @items.size - @view_size, 0 ].max
            end
          end
        end

        def cursor_page_down
          unless @items.empty?
            @cursor = if @cursor == @items.size - 1
              0
            elsif @cursor == (@view_position + @view_size - 1)
              [ @cursor + @view_size - 1, @items.size - 1 ].min
            else
              [ @view_position + @view_size - 1, @items.size - 1 ].min
            end

            if @cursor < @view_position
              @view_position = 0
            elsif @cursor >= @view_position + @view_size
              @view_position = @cursor - @view_size + 1
            end
          end
        end

        def paint ctx
          ctx.save do
            content = if @items.empty?
              %w[Empty]
            else
              @items
            end

            ctx.font = "Arial:10"

            sizings = _calculate_sizings ctx, content
            draw_width = _calculate_width sizings
            draw_height = _calculate_height sizings

            ctx.color = 0x202020
            ctx.fill_rect @x, @y, draw_width, draw_height

            ctx.color = 0xD602DD

            content.zip(sizings).slice(view_position, view_size).reduce([]) do |m,v|
              m + ([
                [
                  v[0],
                  [
                    v[1][0],
                    (m.empty? ? 0 : m.last[1][1] + m.last[1][2]),
                    v[1][1],
                  ]
                ]
              ])
            end.each_with_index do |e,i|
              if @items.empty? or @cursor != (i + view_position)
                ctx.draw_text e[0].to_s, @x + padding, @y + e[1][1] + padding
              else
                ctx.save do
                  ctx.color = 0xD602DD
                  ctx.fill_rect @x, @y + padding + e[1][1], draw_width, e[1][2]

                  ctx.color = 0x202020
                  ctx.draw_text e[0].to_s, @x + padding, @y + e[1][1] + padding
                end
              end
            end

            ctx.draw_rect @x, @y, draw_width, draw_height
          end
        end

        private

        def _calculate_sizings ctx, items
          items.map do |e|
            ctx.size_of_text e.to_s
          end
        end

        def _calculate_width sizings
          sizings.map { |e| e[0] }.max + (padding * 2)
        end

        def _calculate_height sizings
          sizings.slice(view_position, view_size).map do |e|
            e[1]
          end.sum + (padding * 2)
        end
      end

      class EditorState
        attr_accessor :edit_mode
        attr_accessor :selected
        attr_accessor :cursor
        attr_accessor :grid
        attr_reader :menu

        def initialize
          self.edit_mode = false
          self.selected = []
          self.cursor = [ 0, 0 ]
          self.grid = [ 8, 8 ]
        end

        def set_new_entity_edit_mode
          self.edit_mode = :new_entity
          @menu = MenuState.new cursor[0], cursor[1], Dungeon::Core::Entity.registry
        end

        def enable_edit_mode
          self.edit_mode = :default
          @menu = nil
        end

        def disable_edit_mode
          self.edit_mode = false
        end

        def put_cursor x, y
          self.cursor[0] = (x.to_i / grid[0]) * grid[0]
          self.cursor[1] = (y.to_i / grid[1]) * grid[1]
        end

        def set_selection entities, collection
          selected.clear
          entities.each do |e|
            index = collection.find_index { |f| f.equal?(e) }
            selected << index unless index.nil?
          end
        end

        def move_selection direction, collection
          case direction
          when "left"
            selected.each { |e| collection[e].x -= grid[0] }
          when "right"
            selected.each { |e| collection[e].x += grid[0] }
          when "up"
            selected.each { |e| collection[e].y -= grid[1] }
          when "down"
            selected.each { |e| collection[e].y += grid[1] }
          end
        end

        def delete_selection collection
          selected.map { |e| collection[e] }.each { |e| e.remove }
          selected.clear
        end

        def copy_selection collection
          ents = selected.map { |e| collection[e] }
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

        def next_selection collection
          if selected.size > 1
            tmp = selected[0]
            selected.clear
            selected << tmp
          elsif selected.size == 1
            loop do
              selected[0] = (selected[0] + 1) % collection.size
              e = collection[selected[0]]
              break if e.kind_of?(Dungeon::Common::PositionAspect)
            end
          end
        end

        def previous_selection collection
          if selected.size > 1
            tmp = selected[0]
            selected.clear
            selected << tmp
          elsif selected.size == 1
            loop do
              selected[0] = (selected[0] - 1) % collection.size
              e = collection[selected[0]]
              break if e.kind_of?(Dungeon::Common::PositionAspect)
            end
          end
        end

        def assign_selection key, value, collection
          selected.map { |e| collection[e] }.each do |e|
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

        def single_select x, y, collection
          not (collection.find_index do |e|
            e.kind_of?(Dungeon::Common::PositionAspect) and
              Dungeon::Core::Collision.check_point([ x, y ], e)
          end.tap do |o|
            selected.clear
            selected << o unless o.nil?
          end.nil?)
        end

        def multi_select x, y, collection
          not (collection.find_index do |e|
            e.kind_of?(Dungeon::Common::PositionAspect) and
              Dungeon::Core::Collision.check_point([ x, y ], e)
          end.tap do |o|
            selected << o unless o.nil?
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

        def single_select_cursor collection
          single_select cursor[0], cursor[1], collection
        end

        def multi_select_cursor collection
          multi_select cursor[0], cursor[1], collection
        end

        def paint ctx, collection
          ctx.color = 0xD602DD

          collection.each_with_index do |e,i|
            if e.kind_of? Dungeon::Common::PositionAspect
              if self.selected.include? i
                ctx.save do
                  ctx.color = 0x00E08E
                  ctx.draw_rect e.x.to_i, e.y.to_i, e.width.to_i, e.height.to_i
                end
              else 
                ctx.draw_rect e.x.to_i, e.y.to_i, e.width.to_i, e.height.to_i
              end
            end
          end

          unless @menu.nil?
            @menu.paint ctx
          else
            ctx.color = 0xFFFFFF
            ctx.draw_rect self.cursor[0], self.cursor[1], 8, 8
          end
        end
      end

      on :new do
        @editor_state = EditorState.new
      end

      before :interval do 
        stop! if @editor_state.edit_mode
      end

      on :keydown do |key,mod|
        case @editor_state.edit_mode
        when :default
          case key
          when "f1"
            @editor_state.disable_edit_mode
          when "escape"
            @editor_state.clear_selection
          when "backspace", "delete"
            @editor_state.delete_selection self.children
          when "left", "right", "up", "down"
            @editor_state.move_selection key, self.children if mod.shift
            @editor_state.move_cursor key
          when "enter", "return"
            copies = @editor_state.copy_selection self.children
            if copies.empty?
              @editor_state.set_new_entity_edit_mode
            else
              self.add_bulk copies
              @editor_state.set_selection copies, self.children
            end
          when "space"
            if mod.ctrl
              @editor_state.multi_select_cursor self.children
            else
              @editor_state.single_select_cursor self.children
            end
          when "tab"
            if mod.shift
              @editor_state.previous_selection self.children
            else
              @editor_state.next_selection self.children
            end
          end
        when :new_entity
          case key
          when "escape"
            @editor_state.enable_edit_mode
          when "enter", "return"
            klass = Dungeon::Core::Entity.registry[@editor_state.menu.cursor]
            entity = klass.new.tap do |o|
              o.x = @editor_state.cursor[0]
              o.y = @editor_state.cursor[1]
            end
            self.add entity

            @editor_state.enable_edit_mode
            @editor_state.set_selection [ entity ], self.children
          when "up"
            @editor_state.menu.cursor_up
          when "down"
            @editor_state.menu.cursor_down
          when "page_up"
            @editor_state.menu.cursor_page_up
          when "page_down"
            @editor_state.menu.cursor_page_down
          end
        else
          @editor_state.enable_edit_mode if key == "f1"
        end
      end

      on :mousedown do |x,y,button,mod|
        if @editor_state.edit_mode and button == "left"
          @editor_state.enable_edit_mode
          if mod.ctrl
            @editor_state.multi_select x, y, self.children
          else
            unless @editor_state.single_select x, y, self.children
              @editor_state.put_cursor x, y
            end
          end
        end
      end

      after :draw do
        next if not @editor_state.edit_mode
        get_var("ctx").tap do |ctx|
          @editor_state.paint ctx, self.children
        end
      end

      on :console do |args|
        case args[0]
        when /^save$/i
          File.write(args[1], JSON.pretty_generate({
            "meta" => {
              "schema" => "dungeon",
            },
            "background" => self.background,
            "width" => self.width,
            "height" => self.height,
            "entities" => self.each.to_a.select do |e|
              e.respond_to? :savable_dump
            end.map { |e| e.savable_dump },
          }))
          stop!
        when /^set$/i
          if @editor_state.edit_mode
            args.dup.tap { |o| o.shift }.each do |e|
              key, value = e.split("=", 2)
              key = key.strip
              value = JSON.parse(value)
              @editor_state.assign_selection key, value, self.children
            end
          end
        end
      end
    end
  end
end
