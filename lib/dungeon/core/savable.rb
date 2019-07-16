# frozen_string_literal: true

module Dungeon
  module Core
    module Savable
      module ClassMethods
        def savable *fields
          (@savable ||= []).tap do |o|
            o.concat fields.flatten.map(&:to_s)
          end
        end

        def saveable_load data
          self.new.tap do |o|
            data.select { |k, _| self.savable.include?(k) }.each do |k, v|
              o.send("%s=" % k, v)
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

      def self.load_const name
        const_get(name.split("::").reverse.each_with_index.map do |e, i|
          e.split("_").map do |f|
            f.downcase.tap do |o|
              o[0] = o[0].upcase
            end
          end.join.tap do |o|
            o << "Entity" if i.zero?
          end
        end.reverse.join("::"))
      end

      def self.load data
        data = data.dup
        load_const(data["type"]).saveable_load(data)
      end

      def self.included klass
        klass.instance_eval do
          extend Dungeon::Core::Savable::ClassMethods
        end
      end

      def savable_dump
        h = self.to_h
        ([ "type" ] + self.class.savable).reduce({}) do |m, v|
          m.merge({ v => h[v] })
        end
      end
    end
  end
end
