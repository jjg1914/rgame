module Dungeon
  module Common
    module Gui
      class Menu
        attr_accessor :items
        attr_accessor :cursor
        attr_accessor :padding
        attr_accessor :view_size
        attr_accessor :view_position

        def initialize items
          self.items = items
          self.cursor = 0
          self.padding = 4
          self.view_size = 5
          self.view_position = 0
        end

        def cursor direction
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

        def page direction
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

        def paint ctx, x, y
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
            ctx.fill_rect x, y, draw_width, draw_height

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
                ctx.draw_text e[0].to_s, x + padding, y + e[1][1] + padding
              else
                ctx.save do
                  ctx.color = 0xD602DD
                  ctx.fill_rect x, y + padding + e[1][1], draw_width, e[1][2]

                  ctx.color = 0x202020
                  ctx.draw_text e[0].to_s, x + padding, y + e[1][1] + padding
                end
              end
            end

            ctx.draw_rect x, y, draw_width, draw_height
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
    end
  end
end
