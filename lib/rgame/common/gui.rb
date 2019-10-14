# frozen_string_literal: true

require "rgame/core/entity"
require "rgame/core/aspect"
require "rgame/common/collection_entity"

module RGame
  module Common
    module Gui
      module Widget
        include RGame::Core::Aspect

        attr_accessor :x
        attr_accessor :y
        attr_accessor :padding
        attr_accessor :color
        attr_accessor :background
        attr_accessor :highlight

        on "new" do
          self.x = 0
          self.y = 0
          self.padding = 4
          self.color = 0xD602DD
          self.background = 0x202020
          self.highlight = 0x224df9
        end

        on "remove" do
          self.blur
        end

        def focus
          return if self.parent.nil? or self.parent.focused == self

          self.parent.focused = self
        end

        def blur
          return if self.parent.nil? or self.parent.focused != self

          self.parent.focused = nil
        end
      end

      class Container < CollectionEntity
        attr_reader :focused

        on "keydown" do |key, mod|
          unless self.focused.nil?
            self.focused.emit "keydown", key, mod
            stop!
          end
        end

        on "keyrepeat" do |key, mod|
          unless self.focused.nil?
            self.focused.emit "keyrepeat", key, mod
            stop!
          end
        end

        on "keyup" do |key, mod|
          next if self.focused.nil?

          self.focused.emit "keyup", key, mod
          stop!
        end

        def focused= value
          self.focused&.emit "blur"
          @focused = value
          self.focused&.emit "focus"
        end
      end

      class Input < RGame::Core::Entity
        module CursorAspect
          include RGame::Core::Aspect

          attr_accessor :cursor

          on "keydown" do |key, mod|
            case key
            when "left", "right"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.alt) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                if mod.shift
                  self.move_cursor_word_select key
                else
                  self.move_cursor_word key
                  self.selection = nil
                end
              elsif mod.shift
                self.move_cursor_select key
              else
                self.move_cursor key
                self.selection = nil
              end
            when "home", "end"
              if mod.shift
                self.move_cursor_line_select key
              else
                self.move_cursor_line key
                self.selection = nil
              end
            end
          end

          on "keyrepeat" do |key, mod|
            case key
            when "left", "right"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.alt) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil?  and mod.ctrl)
                self.move_cursor_word key
              else
                self.move_cursor key
              end
            when "home", "end"
              self.move_cursor_line key
            end
          end

          def move_cursor direction
            case direction
            when "left"
              self.cursor = [ self.cursor - 1, 0 ].max
              _invalidate! if self.cursor < self.fit.first
            when "right"
              self.cursor = [ self.cursor + 1, self.text.size ].min
              _invalidate! if self.cursor > self.fit.last
            end
          end

          def move_cursor_select direction
            _select_movement { self.move_cursor direction }
          end

          def move_cursor_word direction
            case direction
            when "left"
              _move_cursor_word_left
            when "right"
              _move_cursor_word_right
            end
          end

          def move_cursor_word_select direction
            _select_movement { self.move_cursor_word direction }
          end

          def move_cursor_line direction
            case direction
            when "home"
              self.cursor = 0
              _invalidate! if self.cursor < self.fit.first
            when "end"
              self.cursor = self.text.size
              _invalidate! if self.cursor > self.fit.last
            end
          end

          def move_cursor_line_select direction
            _select_movement { self.move_cursor_line direction }
          end

          private

          def _select_movement
            old_cursor = self.cursor

            yield

            self.selection = if self.selection.nil?
              first = [ self.cursor, old_cursor ].min
              last = [ self.cursor - 1, old_cursor - 1 ].max
              first..last
            elsif old_cursor < self.cursor and self.selection.empty?
              self.selection.first..(self.cursor - 1)
            elsif old_cursor == self.selection.first
              self.cursor..self.selection.last
            else
              self.selection.first..(self.cursor - 1)
            end
          end

          def _move_cursor_word_left
            index = self.text.rindex(/\b/, [ self.cursor - 1, 0 ].max)
            if index == self.cursor - 1
              index = self.text.rindex(/\b/, [ index - 1, 0 ].max)
            end
            self.cursor = if index.nil?
              0
            else
              self.cursor = [ index, 0 ].max
            end
            _invalidate! if self.cursor < self.fit.first
          end

          def _move_cursor_word_right
            index = self.text.index(/\b/, self.cursor + 1)
            self.cursor = if index.nil?
              self.text.size
            else
              [ index + 1, self.text.size ].min
            end
            _invalidate! if self.cursor > self.fit.last
          end
        end

        module SelectionAspect
          include RGame::Core::Aspect

          attr_accessor :selection

          on "keydown" do |key, mod|
            case key
            when "a"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.select_all
              end
            end
          end

          def select_all
            self.selection = (0..(self.text.size - 1))
            self.cursor = self.text.size
            _invalidate!
          end
        end

        module CopyPasteAspect
          include RGame::Core::Aspect

          on "keydown" do |key, mod|
            case key
            when "x"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.cut
              end
            when "c"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.copy
              end
            when "v"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.paste
              end
            end
          end

          def cut
            return if self.selection.nil? or self.selection.empty?

            text_slice = self.text.slice(self.selection)
            RGame::Core::SDL2.SDL_SetClipboardText text_slice
            self._impl_delete self.selection
          end

          def copy
            return if self.selection.nil? or self.selection.empty?

            text = self.text.slice(self.selection)
            RGame::Core::SDL2.SDL_SetClipboardText text
          end

          def paste
            return unless RGame::Core::SDL2.SDL_HasClipboardText

            text = RGame::Core::SDL2.SDL_GetClipboardText
            if self.selection.nil? or self.selection.empty?
              self._impl_insert self.cursor, text
            else
              self._impl_replace self.selection, text
            end
          end
        end

        module UndoRedoAspect
          include RGame::Core::Aspect

          on "new" do
            @undo_stack = []
            @undo_pointer = 0
          end

          on "keydown" do |key, mod|
            case key
            when "z"
              if !(/darwin/ =~ RUBY_PLATFORM).nil? and mod.super
                if mod.shift
                  self.redo
                else
                  self.undo
                end
              elsif (/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl
                self.undo
              end
            when "y"
              self.redo if (/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl
            end
          end

          def undo
            return if @undo_pointer.zero?

            case @undo_stack[@undo_pointer - 1]
            when :replace
              _undo_replace
            when :insert
              _undo_insert
            when :delete
              _undo_delete
            else
              operator = @undo_stack[@undo_pointer - 1].inspect
              raise "unknown operator: %s" % operator
            end
          end

          def redo
            return if @undo_pointer == @undo_stack.size

            _redo_pointer_to_next_operator

            case @undo_stack[@undo_pointer - 1]
            when :replace
              _redo_replace
            when :insert
              _redo_insert
            when :delete
              _redo_delete
            else
              operator = @undo_stack[@undo_pointer - 1].inspect
              raise "unknown operator: %s" % operator
            end
          end

          private

          def _undo_replace
            first = @undo_stack[@undo_pointer - 4].first
            last = first + (@undo_stack[@undo_pointer - 3].size - 1)
            self.text.slice! first..last
            self.text.insert first, @undo_stack[@undo_pointer - 2]
            self.cursor = first + @undo_stack[@undo_pointer - 2].size
            @undo_pointer -= 4
            _invalidate!
          end

          def _undo_insert
            first = @undo_stack[@undo_pointer - 3]
            last = first + (@undo_stack[@undo_pointer - 2].size - 1)
            self.text.slice! first..last
            self.cursor = first
            @undo_pointer -= 3
            _invalidate!
          end

          def _undo_delete
            first = if @undo_stack[@undo_pointer - 3].respond_to? :first
              @undo_stack[@undo_pointer - 3].first
            else
              @undo_stack[@undo_pointer - 3].to_i
            end
            self.text.insert first, @undo_stack[@undo_pointer - 2]
            self.cursor = first + @undo_stack[@undo_pointer - 2].size
            @undo_pointer -= 3
            _invalidate!
          end

          def _redo_pointer_to_next_operator
            while @undo_pointer < @undo_stack.size
              @undo_pointer += 1
              break if @undo_stack[@undo_pointer].is_a? Symbol
            end
            @undo_pointer += 1
          end

          def _redo_replace
            first = @undo_stack[@undo_pointer - 4].first
            last = first + (@undo_stack[@undo_pointer - 2].size - 1)
            self.text.slice!(first..last)
            self.text.insert(first, @undo_stack[@undo_pointer - 3])
            self.cursor = first + @undo_stack[@undo_pointer - 3].size
            _invalidate!
          end

          def _redo_insert
            first = (@undo_stack[@undo_pointer - 3])
            self.text.insert(first, @undo_stack[@undo_pointer - 2])
            self.cursor = first + @undo_stack[@undo_pointer - 2].size
            _invalidate!
          end

          def _redo_delete
            first = if @undo_stack[@undo_pointer - 3].respond_to? :first
              @undo_stack[@undo_pointer - 3].first
            else
              @undo_stack[@undo_pointer - 3].to_i
            end
            last = first + (@undo_stack[@undo_pointer - 2].size - 1)
            self.text.slice!(first..last)
            self.cursor = first
            _invalidate!
          end
        end

        module EraseAspect
          include RGame::Core::Aspect

          on "keydown" do |key, mod|
            case key
            when "backspace"
              if not self.selection.nil?
                self.delete_selection
              elsif (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.alt) or
                    ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.backspace_word
              else
                self.backspace
              end
            when "delete"
              if not self.selection.nil?
                self.delete_selection
              elsif (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.alt) or
                    ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.delete_word
              else
                self.delete
              end
            end
          end

          on "keyrepeat" do |key, mod|
            case key
            when "backspace"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.alt) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil? and mod.ctrl)
                self.backspace_word
              else
                self.backspace
              end
            when "delete"
              if (!(/darwin/ =~ RUBY_PLATFORM).nil? and mod.alt) or
                 ((/darwin/ =~ RUBY_PLATFORM).nil?  and mod.ctrl)
                self.delete_word
              else
                self.delete
              end
            end
          end

          def backspace
            return if self.cursor.zero?

            self._impl_delete self.cursor - 1
            self.cursor -= 1
            _invalidate!
          end

          def backspace_word
            return if self.cursor.zero?

            index = self.text.rindex(/\b/, [ self.cursor - 1, 0 ].max)
            if index == self.cursor - 1
              index = self.text.rindex(/\b/, [ index - 1, 0 ].max)
            end

            self.cursor = if index.nil?
              self._impl_delete(0..(self.cursor - 1))
              0
            else
              self._impl_delete(index..(self.cursor - 1))
              [ index, 0 ].max
            end

            _invalidate!
          end

          def delete
            return if self.cursor == self.text.size

            self._impl_delete(self.cursor) unless self.cursor == self.text.size
            _invalidate!
          end

          def delete_word
            return if self.cursor == self.text.size

            index = self.text.index(/\b/, self.cursor + 1)
            index = self.text.index(/\b/, index + 1) if index == self.cursor + 1

            if index.nil?
              self._impl_delete self.cursor..-1
            else
              self._impl_delete self.cursor...index
            end

            _invalidate!
          end

          def delete_selection
            self._impl_delete(self.selection)
            self.cursor = self.selection.first
            self.selection = nil

            _invalidate!
          end
        end

        module TextInputAspect
          include RGame::Core::Aspect

          on "focus" do
            self.ctx.events.text_input_mode = true
          end

          on "blur" do
            self.ctx.events.text_input_mode = false
          end

          on "textinput" do |text|
            self.textinput text
          end

          def textinput text
            if not self.selection.nil?
              self._impl_replace(self.selection, text)
              self.cursor = [
                self.selection.first + text.size,
                self.text.size,
              ].min
              self.selection = nil
            elsif self.mode == :replace
              self._impl_replace((self.cursor..self.cursor), text)
              self.cursor = [ self.cursor + text.size, self.text.size ].min
            else
              self._impl_insert(self.cursor, text)
              self.cursor = [ self.cursor + text.size, self.text.size ].min
            end

            _invalidate!
          end
        end

        module TextFitHelpers
          def fit_text_right ctx, text, sizing, cursor
            left = 0
            right = cursor

            while left < right
              mid = (((right - left) / 2.0) + left).floor
              fit_sizing = ctx.renderer.size_of_text(text.slice(mid..cursor))
              if fit_sizing[0] < sizing[0]
                right = mid
              else
                left = mid + 1
              end
            end

            (left..self.cursor)
          end

          def fit_text_left ctx, text, sizing, cursor, old_fit
            init = if old_fit.nil?
              cursor
            else
              [ cursor, old_fit.first ].min
            end
            left = init
            right = text.size - 1

            while left < right
              mid = (((right - left) / 2.0) + left).floor
              fit_sizing = ctx.renderer.size_of_text(text.slice(init..mid))
              if fit_sizing[0] < sizing[0]
                left = mid + 1
              else
                right = mid
              end
            end

            (init..left)
          end
        end

        include RGame::Common::Gui::Widget
        include CursorAspect
        include CopyPasteAspect
        include UndoRedoAspect
        include EraseAspect
        include TextInputAspect
        include SelectionAspect
        include TextFitHelpers

        attr_reader :text
        attr_accessor :mode

        on "new" do
          self.text = String.new # literals are frozen
          self.cursor = 0
          self.mode = :insert
        end

        on "keydown" do |key, _|
          case key
          when "enter", "return"
            self.broadcast "commit", self.text
          when "insert"
            self.toggle_mode
          end
        end

        on "draw" do
          self.paint self.ctx
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

        def paint ctx
          ctx.save do
            ctx.renderer.font = "Arial:10"

            sizings = _calculate_sizing ctx, self.text
            draw_width = sizings[0] + (self.padding * 2)
            draw_height = sizings[1] + (self.padding * 2)

            ctx.renderer.color = self.background
            ctx.renderer.fill_rect self.x, self.y, draw_width, draw_height

            ctx.renderer.color = self.color
            image = _text_image ctx, text, sizings

            _paint_selection ctx

            ctx.renderer.color = self.color
            ctx.renderer.source = image
            ctx.renderer.draw_image self.x + self.padding, self.y + self.padding

            _paint_cursor ctx, sizings

            ctx.renderer.stroke_rect self.x, self.y, draw_width, draw_height
          end
        end

        def text= value
          @text = value
          _invalidate!
        end

        protected

        attr_accessor :fit

        def _invalidate!
          @text_invalid = true
        end

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

        def _paint_selection ctx
          return if self.selection.nil?

          visible = _visible_selection
          sizing = ctx.renderer.size_of_text((self.text + " ").slice(visible))

          offset_x = if visible.first > self.fit.first
            slice_range = self.fit.first...visible.first
            text_slice = (self.text + " ").slice slice_range
            ctx.renderer.size_of_text(text_slice).first
          else
            0
          end

          ctx.renderer.color = self.highlight
          ctx.renderer.fill_rect self.x + self.padding + offset_x,
                                 self.y + self.padding,
                                 *sizing
        end

        def _paint_cursor ctx, sizings
          text_slice = self.text.slice(self.fit.first...self.cursor)
          cursor_x = ctx.renderer.size_of_text(text_slice).first

          if self.mode == :replace
            size = ctx.renderer.size_of_text((self.text + " ")[self.cursor])
            ctx.renderer.stroke_rect self.x + cursor_x + self.padding,
                                     self.y + size[1] + self.padding,
                                     size[0], 1
          elsif self.mode == :insert
            ctx.renderer.stroke_rect self.x + cursor_x + self.padding,
                                     self.y + self.padding,
                                     1, sizings[1]
          end
        end

        def _visible_selection
          return if self.selection.nil?

          first = [ self.selection.first, self.fit.first ].max
          last = [ self.selection.last, self.fit.last ].min
          first..last
        end

        def _calculate_sizing ctx, text
          ctx.renderer.size_of_text(text + " ").tap do |o|
            o[0] = 192
          end
        end

        def _text_image ctx, text, sizing
          if @text_invalid
            @text_image&.free
            self.fit = if not self.fit.nil? and self.cursor > self.fit.last
              fit_text_right ctx, text + " ", sizing, self.cursor
            else
              fit_text_left ctx, text + " ", sizing, self.cursor, self.fit
            end
            @text_image = ctx.renderer.create_text((text + " ").slice(self.fit))
            @text_invalid = false
          end
          @text_image
        end
      end

      class Menu < RGame::Core::Entity
        include RGame::Common::Gui::Widget

        module CursorAspect
          include RGame::Core::Aspect

          attr_accessor :cursor

          on "keydown" do |key, _|
            case key
            when "up", "down"
              self.cursor_move key
            when "page_up", "page_down"
              self.cursor_move_page key[5..-1]
            end
          end

          on "keyrepeat" do |key, _|
            case key
            when "up", "down"
              self.cursor_move key
            when "page_up", "page_down"
              self.cursor_move_page key[5..-1]
            end
          end

          def cursor_move direction
            case direction
            when "up"
              _cursor_move_up
            when "down"
              _cursor_move_down
            end
          end

          def cursor_move_page direction
            case direction
            when "up"
              _cursor_move_page_up
            when "down"
              _cursor_move_page_down
            end
          end

          def _cursor_move_up
            return if self.items.empty?

            self.cursor = (self.cursor - 1) % self.items.size
            _view_bound_up
          end

          def _cursor_move_down
            return if self.items.empty?

            self.cursor = (self.cursor + 1) % self.items.size
            _view_bound_down
          end

          def _cursor_move_page_up
            return if self.items.empty?

            self.cursor = if self.cursor.zero?
              [ self.items.size - 1, 0 ].max
            elsif self.cursor == self.view_position
              [ self.cursor - self.view_size + 1, 0 ].max
            else
              self.view_position
            end

            _view_bound_up
          end

          def _cursor_move_page_down
            return if self.items.empty?

            self.cursor = if self.cursor == self.items.size - 1
              0
            elsif self.cursor == (self.view_position + self.view_size - 1)
              [
                self.cursor + self.view_size - 1,
                self.items.size - 1,
              ].min
            else
              [
                self.view_position + self.view_size - 1,
                self.items.size - 1,
              ].min
            end

            _view_bound_down
          end

          def _view_bound_up
            _view_bound self.cursor, [
              self.items.size - self.view_size,
              0,
            ].max
          end

          def _view_bound_down
            _view_bound 0, self.cursor - self.view_size + 1
          end

          def _view_bound top, bottom
            if self.cursor < self.view_position
              self.view_position = top
            elsif self.cursor >= self.view_position + self.view_size
              self.view_position = bottom
            end
          end
        end

        include CursorAspect

        attr_reader :items
        attr_accessor :view_size
        attr_accessor :view_position

        on "new" do
          self.x = 0
          self.y = 0
          self.items = []
          self.cursor = 0
          self.view_size = 5
          self.view_position = 0
        end

        on "keydown" do |key, _|
          case key
          when "enter", "return"
            self.broadcast "commit", self.items[self.cursor]
          end
        end

        on "draw" do
          self.paint self.ctx
        end

        def items= value
          @text_images&.each(&:free)
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

            ctx.renderer.font = "Arial:10"

            _render_text ctx, content

            sizings = _calculate_sizings ctx, content
            draw_width = _calculate_width sizings
            draw_height = _calculate_height sizings

            ctx.renderer.color = self.background
            ctx.renderer.fill_rect x, y, draw_width, draw_height

            ctx.renderer.color = self.color

            _paint_items content, sizings, draw_width

            ctx.renderer.stroke_rect x, y, draw_width, draw_height
          end
        end

        private

        def _paint_items content, sizings, draw_width
          content
            .zip(sizings)
            .slice(view_position, view_size)
            .reduce([]) do |m, v|
              m + [
                [
                  v[0],
                  [
                    v[1][0],
                    (m.empty? ? 0 : m.last[1][1] + m.last[1][2]),
                    v[1][1],
                  ],
                ],
              ]
            end.each_with_index do |e, i|
              _paint_item e[1], i, draw_width
            end
        end

        def _paint_item sizing, index, draw_width
          if not @items.empty? and @cursor == (index + view_position)
            ctx.save do
              ctx.renderer.color = self.highlight
              ctx.renderer.fill_rect x, y + padding + sizing[1],
                                     draw_width, sizing[2]
            end
          end

          ctx.renderer.source = @text_images[index + view_position]
          ctx.renderer.draw_image x + padding, y + sizing[1] + padding
        end

        def _render_text ctx, items
          return unless @text_images.nil?

          @text_images = items.map do |e|
            ctx.renderer.create_text(e.to_s)
          end
        end

        def _calculate_sizings ctx, items
          items.map do |e|
            ctx.renderer.size_of_text e.to_s
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
