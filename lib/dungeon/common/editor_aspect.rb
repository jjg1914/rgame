require "json"

require "dungeon/core/aspect"
require "dungeon/core/savable"
require "dungeon/common/position_aspect"

module Dungeon
  module Common
    module EditorAspect 
      include Dungeon::Core::Aspect

      on :new do
        @edit_mode = false
      end

      before :interval do 
        stop! if @edit_mode
      end

      on :keydown do |key,mod|
        if @edit_mode
          case key
          when "f1"
            @edit_mode = false
          when "backspace", "delete"
            unless @selected.nil?
              self.children[@selected].remove
              @selected = nil
            end
          when "left"
            unless @selected.nil?
              self.children[@selected].x -= 8
            end
            @mouse_state[0] -= 8 unless @mouse_state.nil?
          when "right"
            unless @selected.nil?
              self.children[@selected].x += 8
            end
            @mouse_state[0] == 8 unless @mouse_state.nil?
          when "up"
            unless @selected.nil?
              self.children[@selected].y -= 8
            end
            @mouse_state[1] -= 8 unless @mouse_state.nil?
          when "down"
            unless @selected.nil?
              self.children[@selected].y += 8
            end
            @mouse_state[1] += 8 unless @mouse_state.nil?
          when "tab"
            unless @selected.nil?
              if mod.shift
                loop do
                  @selected = (@selected - 1) % self.children.size
                  break if self.children[@selected].kind_of?(Dungeon::Common::PositionAspect)
                end
              else
                loop do
                  @selected = (@selected + 1) % self.children.size
                  break if self.children[@selected].kind_of?(Dungeon::Common::PositionAspect)
                end
              end
            end
          end
        else
          @edit_mode = true if key == "f1"
        end
      end

      on :mousedown do |x,y,button|
        if @edit_mode and button == "left"
          @selected = self.each.find_index do |e|
            e.kind_of?(Dungeon::Common::PositionAspect) and
              Dungeon::Core::Collision.check_point([ x, y ], e)
          end

          if @selected.nil?
            @mouse_state = ((x.to_i / 8) * 8), ((y.to_i / 8) * 8)
          else
            @mouse_state = nil
          end
        end
      end

      after :draw do
        next if not @edit_mode
        get_var("ctx").tap do |ctx|
          ctx.color = 0xD602DD

          self.each.each_with_index do |e,i|
            if e.kind_of? Dungeon::Common::PositionAspect
              if @selected == i
                ctx.save do
                  ctx.color = 0x00E08E
                  ctx.draw_rect e.x.to_i, e.y.to_i, e.width.to_i, e.height.to_i
                end
              else 
                ctx.draw_rect e.x.to_i, e.y.to_i, e.width.to_i, e.height.to_i
              end
            end
          end

          unless @mouse_state.nil?
            ctx.color = 0xFFFFFF
            ctx.draw_rect @mouse_state[0], @mouse_state[1], 8, 8
          end
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
          if @edit_mode and not @selected.nil?
            target = self.children[@selected]
            args.dup.tap { |o| o.shift }.each do |e|
              key, value = e.split("=", 2)
              begin
                target.send("%s=" % key.strip, JSON.parse(value))
              rescue
                STDERR.puts $!.message
              end
            end
          end
        when /^add$/i
          if @edit_mode and not @mouse_state.nil?
            self.add(Dungeon::Core::Savable.load({
              "type" => args[1].strip,
              "x" => @mouse_state[0],
              "y" => @mouse_state[1],
            }))
          end
        end
      end
    end
  end
end
