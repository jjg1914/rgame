require "dungeon/core/entity"
require "dungeon/core/aspect"
require "dungeon/common/collection_entity"

module Dungeon
  module Common
    module Gui
      module Widget
        include Dungeon::Core::Aspect

        attr_accessor :x
        attr_accessor :y
        attr_accessor :padding
        attr_accessor :color
        attr_accessor :background
        attr_accessor :highlight

        on :new do
          self.x = 0
          self.y = 0
          self.padding = 4
          self.color = 0xD602DD
          self.background = 0x202020
          self.highlight = 0x224df9
        end

        on :remove do
          self.blur
        end

        def focus
          if not self.parent.nil? and self.parent.focused != self
            self.parent.focused = self
          end
        end

        def blur
          if not self.parent.nil? and self.parent.focused == self
            self.parent.focused = nil
          end
        end
      end

      class Container < CollectionEntity
        attr_reader :focused

        on :keydown do |key,mod|
          unless self.focused.nil?
            self.focused.emit(:keydown, key, mod)
            stop!
          end
        end

        on :keyrepeat do |key,mod|
          unless self.focused.nil?
            self.focused.emit(:keyrepeat, key, mod)
            stop!
          end
        end

        on :keyup do |key,mod|
          unless self.focused.nil?
            self.focused.emit(:keyup, key, mod)
            stop!
          end
        end

        def focused= value
          self.focused.emit(:blur) unless self.focused.nil?
          @focused = value
          self.focused.emit(:focus) unless self.focused.nil?
        end
      end

      class Input < Dungeon::Core::Entity
        include Dungeon::Common::Gui::Widget

        attr_accessor :text
        attr_accessor :cursor
        attr_accessor :selection
        attr_accessor :mode

        on :new do
          self.text = ""
          self.cursor = 0
          self.mode = :insert
          @undo_stack = []
          @undo_pointer = 0
        end

        on :focus do
          get_var("ctx").tap { |o| o.text_input_mode = true unless o.nil? }
        end

        on :blur do
          get_var("ctx").tap { |o| o.text_input_mode = false unless o.nil? }
        end

        on :keydown do |key,mod|
          case key
          when "enter", "return"
            self.broadcast :commit, self.text
          when "left", "right"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.alt) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              if mod.shift
                self.move_cursor_word_select key
              else
                self.move_cursor_word key
                self.selection = nil
              end
            else
              if mod.shift
                self.move_cursor_select key
              else
                self.move_cursor key
                self.selection = nil
              end
            end
          when "home", "end"
            if mod.shift
              self.move_cursor_line_select key
            else
              self.move_cursor_line key
              self.selection = nil
            end
          when "backspace"
            if not self.selection.nil?
              self.delete_selection
            elsif ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.alt) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.backspace_word
            else
              self.backspace
            end
          when "delete"
            if not self.selection.nil?
              self.delete_selection
            elsif ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.alt) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.delete_word
            else
              self.delete
            end
          when "insert"
            self.toggle_mode
          when "a"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.super) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.select_all
            end
          when "x"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.super) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.cut
            end
          when "c"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.super) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.copy
            end
          when "v"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.super) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.paste
            end
          when "z"
            if (/darwin/ =~ RUBY_PLATFORM) != nil and mod.super
              if mod.shift
                self.redo
              else
                self.undo
              end
            elsif (/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl
              self.undo
            end
          when "y"
            if ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl) 
              self.redo
            end
          end
        end

        on :keyrepeat do |key,mod|
          case key
          when "left", "right"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.alt) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.move_cursor_word key
            else
              self.move_cursor key
            end
          when "home", "end"
            self.move_cursor_line key
          when "backspace"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.alt) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.backspace_word
            else
              self.backspace
            end
          when "delete"
            if ((/darwin/ =~ RUBY_PLATFORM) != nil and mod.alt) or
               ((/darwin/ =~ RUBY_PLATFORM) == nil and mod.ctrl)
              self.delete_word
            else
              self.delete
            end
          end
        end

        on :textinput do |text|
          self.textinput text
        end

        on :draw do
          get_var("ctx").tap do |ctx|
            self.paint ctx unless ctx.nil?
          end
        end

        def move_cursor direction
          case direction
          when "left"
            self.cursor = [ self.cursor - 1, 0 ].max
            @text_invalid = true if self.cursor < self.fit.first
          when "right"
            self.cursor = [ self.cursor + 1, self.text.size ].min
            @text_invalid = true if self.cursor > self.fit.last
          end
        end

        def move_cursor_select direction
          _select_movement { self.move_cursor direction }
        end

        def move_cursor_word direction
          case direction
          when "left"
            index = self.text.rindex(%r[\b], [ self.cursor - 1, 0 ].max)
            if index == self.cursor - 1
              index = self.text.rindex(%r[\b], [ index - 1, 0 ].max)
            end
            self.cursor = unless index.nil?
              self.cursor = [ index, 0 ].max
            else
              0
            end
            @text_invalid = true if self.cursor < self.fit.first
          when "right"
            index = self.text.index(%r[\b], self.cursor + 1)
            self.cursor = unless index.nil?
              [ index + 1, self.text.size ].min
            else
              self.text.size
            end
            @text_invalid = true if self.cursor > self.fit.last
          end
        end

        def move_cursor_word_select direction
          _select_movement { self.move_cursor_word direction }
        end

        def move_cursor_line direction
          case direction
          when "home"
            self.cursor = 0
            @text_invalid = true if self.cursor < self.fit.first
          when "end"
            self.cursor = self.text.size
            @text_invalid = true if self.cursor > self.fit.last
          end
        end

        def move_cursor_line_select direction
          _select_movement { self.move_cursor_line direction }
        end

        def select_all
          self.selection = (0..(self.text.size - 1))
          self.cursor = self.text.size
          @text_invalid = true
        end

        def toggle_mode
          self.mode = case self.mode
          when :insert
            :replace
          when :replace
            :insert
          else
            self.mode
          end
        end

        def cut
          unless self.selection.nil? or self.selection.size == 0
            Dungeon::Core::SDL2.SDL_SetClipboardText self.text.slice(self.selection)
            self._impl_delete self.selection
          end
        end

        def copy
          unless self.selection.nil? or self.selection.size == 0
            Dungeon::Core::SDL2.SDL_SetClipboardText self.text.slice(self.selection)
          end
        end

        def paste
          if Dungeon::Core::SDL2.SDL_HasClipboardText
            text = Dungeon::Core::SDL2.SDL_GetClipboardText
            unless self.selection.nil? or self.selection.size == 0
              self._impl_replace self.selection, text
            else
              self._impl_insert self.cursor, text
            end
          end
        end

        def textinput text
          if not self.selection.nil?
            self._impl_replace(self.selection, text)
            self.cursor = [ self.selection.first + text.size, self.text.size ].min
            self.selection = nil
          elsif self.mode == :replace
            self._impl_replace((self.cursor..self.cursor), text)
            self.cursor = [ self.cursor + text.size, self.text.size ].min
          else
            self._impl_insert(self.cursor, text)
            self.cursor = [ self.cursor + text.size, self.text.size ].min
          end
          @text_invalid = true
        end

        def backspace
          unless self.cursor == 0
            self._impl_delete(self.cursor - 1)
            self.cursor -= 1
            @text_invalid = true
          end
        end

        def backspace_word
          unless self.cursor == 0
            index = self.text.rindex(%r[\b], [ self.cursor - 1, 0 ].max)
            if index == self.cursor - 1
              index = self.text.rindex(%r[\b], [ index - 1, 0 ].max)
            end

            self.cursor = unless index.nil?
              self._impl_delete(index..(self.cursor - 1))
              [ index, 0 ].max
            else
              self._impl_delete(0..(self.cursor - 1))
              0
            end

            @text_invalid = true
          end
        end

        def delete
          unless self.cursor == self.text.size
            self._impl_delete(self.cursor) unless self.cursor == self.text.size
            @text_invalid = true
          end
        end

        def delete_word
          unless self.cursor == self.text.size
            index = self.text.index(%r[\b], self.cursor + 1)
            if index = self.cursor + 1
              index = self.text.index(%r[\b], index + 1)
            end
            unless index.nil?
              self._impl_delete(self.cursor...index)
            else
              self._impl_delete(self.cursor..-1)
            end

            @text_invalid = true
          end
        end

        def delete_selection
          self._impl_delete(self.selection)
          self.cursor = self.selection.first
          self.selection = nil
          @text_invalid = true
        end

        def undo
          unless @undo_pointer == 0
            case @undo_stack[@undo_pointer - 1]
            when :replace
              first = (@undo_stack[@undo_pointer - 4].first)
              last = first + (@undo_stack[@undo_pointer - 3].size - 1)
              self.text.slice!(first..last)
              self.text.insert(first, @undo_stack[@undo_pointer - 2])
              self.cursor = first + @undo_stack[@undo_pointer - 2].size
              @undo_pointer -= 4
              @text_invalid = true

            when :insert
              first = (@undo_stack[@undo_pointer - 3])
              last = first + (@undo_stack[@undo_pointer - 2].size - 1)
              self.text.slice!(first..last)
              self.cursor = first
              @undo_pointer -= 3
              @text_invalid = true

            when :delete
              first = if @undo_stack[@undo_pointer - 3].respond_to? :first
                @undo_stack[@undo_pointer - 3].first
              else
                @undo_stack[@undo_pointer - 3].to_i
              end
              self.text.insert(first, @undo_stack[@undo_pointer - 2])
              self.cursor = first + @undo_stack[@undo_pointer - 2].size
              @undo_pointer -= 3
              @text_invalid = true

            else
              raise "unknown operator: %s" % @undo_stack[@undo_pointer - 1].inspect
            end
          end
        end

        def redo
          unless @undo_pointer == @undo_stack.size
            while @undo_pointer < @undo_stack.size
              @undo_pointer += 1
              break if @undo_stack[@undo_pointer].is_a? Symbol
            end
            @undo_pointer += 1

            case @undo_stack[@undo_pointer - 1]
            when :replace
              first = (@undo_stack[@undo_pointer - 4].first)
              last = first + (@undo_stack[@undo_pointer - 2].size - 1)
              self.text.slice!(first..last)
              self.text.insert(first, @undo_stack[@undo_pointer - 3])
              self.cursor = first + @undo_stack[@undo_pointer - 3].size
              @text_invalid = true

            when :insert
              first = (@undo_stack[@undo_pointer - 3])
              self.text.insert(first, @undo_stack[@undo_pointer - 2])
              self.cursor = first + @undo_stack[@undo_pointer - 2].size
              @text_invalid = true

            when :delete
              first = if @undo_stack[@undo_pointer - 3].respond_to? :first
                @undo_stack[@undo_pointer - 3].first
              else
                @undo_stack[@undo_pointer - 3].to_i
              end
              last = first + (@undo_stack[@undo_pointer - 2].size - 1)
              self.text.slice!(first..last)
              self.cursor = first
              @text_invalid = true

            else
              raise "unknown operator: %s" % @undo_stack[@undo_pointer - 1].inspect
            end
          end
        end

        def paint ctx
          ctx.save do
            ctx.font = "Arial:10"

            sizings = _calculate_sizing ctx, self.text
            draw_width = sizings[0] + (self.padding * 2)
            draw_height = sizings[1] + (self.padding * 2)

            ctx.color = self.background
            ctx.fill_rect self.x, self.y, draw_width, draw_height

            ctx.color = self.color
            image = _text_image ctx, text, sizings

            unless self.selection.nil?
              visible = _visible_selection
              sizing = ctx.size_of_text((self.text + " ").slice(visible))

              offset_x = if visible.first > self.fit.first
                ctx.size_of_text((self.text + " ").slice(self.fit.first...visible.first))
              else
                0
              end

              ctx.color = self.highlight
              ctx.fill_rect self.x + self.padding + offset_x[0], self.y + self.padding, *sizing
            end

            ctx.color = self.color
            ctx.source = image
            ctx.draw_image self.x + self.padding, self.y + self.padding

            cursor_x = ctx.size_of_text(self.text.slice(self.fit.first...self.cursor)).first
            if self.mode == :replace
              size = ctx.size_of_text((self.text + " ")[self.cursor])
              ctx.stroke_rect self.x + cursor_x + self.padding, self.y + size[1] + self.padding, size[0], 1
            elsif self.mode == :insert
              ctx.stroke_rect self.x + cursor_x + self.padding, self.y + self.padding, 1, sizings[1]
            end

            ctx.stroke_rect self.x, self.y, draw_width, draw_height
          end
        end

        def text= value
          @text = value
          @text_invalid = true
        end

        protected

        attr_accessor :fit

        def _impl_replace slice, text
          old = self.text.slice!(slice)
          self.text.insert(slice.first, text)
          unless @undo_pointer == @undo_stack.size
            @undo_stack.slice!(@undo_pointer..-1) 
          end
          @undo_stack << slice << text << old << :replace
          @undo_pointer = @undo_stack.size
        end

        def _impl_insert position, text
          self.text.insert(position, text)
          unless @undo_pointer == @undo_stack.size
            @undo_stack.slice!(@undo_pointer..-1) 
          end
          @undo_stack << position << text << :insert
          @undo_pointer = @undo_stack.size
        end

        def _impl_delete slice
          text = self.text.slice!(slice)
          unless @undo_pointer == @undo_stack.size
            @undo_stack.slice!(@undo_pointer..-1) 
          end
          @undo_stack << slice << text << :delete
          @undo_pointer = @undo_stack.size
        end

        private

        def _select_movement 
          old_cursor = self.cursor

          yield

          self.selection = if self.selection.nil?
            first = [ self.cursor, old_cursor ].min
            last = [ self.cursor - 1, old_cursor - 1 ].max
            first..last
          elsif old_cursor < self.cursor and self.selection.size == 0
            self.selection.first..(self.cursor - 1)
          elsif old_cursor == self.selection.first
            self.cursor..self.selection.last
          else
            self.selection.first..(self.cursor - 1)
          end
        end

        def _visible_selection
          unless self.selection.nil?
            first = [ self.selection.first, self.fit.first ].max
            last = [ self.selection.last, self.fit.last ].min
            first..last
          end
        end

        def _calculate_sizing ctx, text
          ctx.size_of_text(text + " ").tap do |o|
            o[0] = 192
          end
        end

        def _text_image ctx, text, sizing
          if @text_invalid 
            @text_image.free unless @text_image.nil?
            self.fit = if not self.fit.nil? and self.cursor > self.fit.last
              _fit_text_right ctx, text + " ", sizing
            else
              _fit_text_left ctx, text + " ", sizing
            end
            @text_image = ctx.create_text((text + " ").slice(self.fit))
            @text_invalid = false
          end
          @text_image
        end

        def _fit_text_right ctx, text, sizing
          left = 0
          right = self.cursor

          while left < right
            mid = (((right - left) / 2.0) + left).floor
            fit_sizing = ctx.size_of_text(text.slice(mid..self.cursor))
            if fit_sizing[0] < sizing[0]
              right = mid
            else
              left = mid + 1
            end
          end

          (left..self.cursor)
        end

        def _fit_text_left ctx, text, sizing
          init = if self.fit.nil?
            self.cursor
          else
            [ self.cursor, self.fit.first ].min
          end
          left = init
          right = text.size - 1

          while left < right
            mid = (((right - left) / 2.0) + left).floor
            fit_sizing = ctx.size_of_text(text.slice(init..mid))
            if fit_sizing[0] < sizing[0]
              left = mid + 1
            else
              right = mid
            end
          end

          (init..left)
        end
      end

      class Menu < Dungeon::Core::Entity
        include Dungeon::Common::Gui::Widget

        attr_accessor :items
        attr_accessor :cursor
        attr_accessor :view_size
        attr_accessor :view_position

        on :new do
          self.x = 0
          self.y = 0
          self.items = []
          self.cursor = 0
          self.view_size = 5
          self.view_position = 0
        end

        on :keydown do |key,mod|
          case key
          when "enter", "return"
            self.broadcast :commit, self.items[self.cursor]
          when "up", "down"
            self.cursor_move key
          when "page_up", "page_down"
            self.cursor_move_page key[5..-1]
          end
        end

        on :keyrepeat do |key,mod|
          case key
          when "up", "down"
            self.cursor_move key
          when "page_up", "page_down"
            self.cursor_move_page key[5..-1]
          end
        end

        on :draw do
          get_var("ctx").tap do |ctx|
            self.paint ctx unless ctx.nil?
          end
        end

        def cursor_move direction
          case direction
          when "up"
            unless @items.empty?
              @cursor = (@cursor - 1) % @items.size

              if @cursor < @view_position
                @view_position = @cursor
              elsif @cursor >= @view_position + @view_size
                @view_position = [ @items.size - @view_size, 0 ].max
              end
            end
          when "down"
            unless @items.empty?
              @cursor = (@cursor + 1) % @items.size
              if @cursor < @view_position
                @view_position = 0
              elsif @cursor >= @view_position + @view_size
                @view_position = @cursor - @view_size + 1
              end
            end
          end
        end

        def cursor_move_page direction
          case direction
          when "up"
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
          when "down"
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
        end

        def items= value
          @text_images.each { |e| e.free } unless @text_images.nil?
          @text_images = nil
          @items = value
        end

        def paint ctx
          ctx.save do
            content = if self.items.empty?
              %w[Empty]
            else
              self.items
            end

            ctx.font = "Arial:10"

            _render_text ctx, content

            sizings = _calculate_sizings ctx, content
            draw_width = _calculate_width sizings
            draw_height = _calculate_height sizings

            ctx.color = self.background
            ctx.fill_rect x, y, draw_width, draw_height

            ctx.color = self.color

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
              if not @items.empty? and @cursor == (i + view_position)
                ctx.save do
                  ctx.color = self.highlight
                  ctx.fill_rect x, y + padding + e[1][1], draw_width, e[1][2]
                end
              end

              ctx.source = @text_images[i + view_position]
              ctx.draw_image x + padding, y + e[1][1] + padding
            end

            ctx.stroke_rect x, y, draw_width, draw_height
          end
        end

        private

        def _render_text ctx, items
          if @text_images.nil?
            @text_images = items.map do |e|
              ctx.create_text(e.to_s)
            end
          end
        end

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
    end
  end
end
