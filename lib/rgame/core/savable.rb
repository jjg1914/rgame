# frozen_string_literal: true

module RGame
  module Core
    module Savable
      module ClassMethods
        def savable *fields
          (@savable ||= []).tap do |o|
            o.concat fields.flatten.map(&:to_s)
          end
        end

        def saveable_load data, context = nil
          self.new(context).tap do |o|
            p = lambda do |u|
              Hash[*u.each_pair.map do |k, v|
                if v.is_a?(data.class)
                  p.call(v).map do |k2, v2|
                    [ [ k ] + k2, v2 ]
                  end
                else
                  [ [ [ k ], v ] ]
                end
              end.flatten(2)]
            end

            p.call(data).select do |k, _|
              self.savable.include?(k.join("."))
            end.each do |k, v|
              k.each_with_index.reduce(o) do |m, v2|
                if v2[1] == k.size - 1
                  m.send("%s=" % v2[0], v)
                else
                  m.send(v2[0])
                end
              end
            end
          end
        end

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @savable = parent.savable.dup
          end
        end
      end

      class << self
        def load_const name
          const_get(name.split("::").reverse.each_with_index.map do |e, i|
            e.split("_").map do |f|
              if f == "rgame"
                "RGame"
              else
                f.downcase.tap do |o|
                  o[0] = o[0].upcase
                end
              end
            end.join.tap do |o|
              o << "Entity" if i.zero?
            end
          end.reverse.join("::"))
        end

        def load data, context = nil
          data = data.dup
          load_const(data["type"]).saveable_load(data, context)
        end

        def included klass
          klass.instance_eval do
            extend RGame::Core::Savable::ClassMethods
          end
        end
      end

      def savable_dump
        h = self.to_h
        ([ "type" ] + self.class.savable).reduce({}) do |m, v|
          m.merge(v.split(".").reverse.reduce(h.dig(*v.split("."))) do |m2, v2|
            { v2 => m2 }
          end)
        end
      end
    end
  end
end
