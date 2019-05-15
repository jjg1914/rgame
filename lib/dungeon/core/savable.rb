module Dungeon
  module Core
    module Savable
      module ClassMethods
        def savable *fields
          (@savable ||= []).tap do |o|
            o.concat fields.flatten.map { |e| e.to_s }
          end
        end

        def saveable_load data
          self.new.tap do |o|
            data.select { |k,v| self.savable.include?(k) }.each do |k,v|
              o.send("%s=" % k, v)
            end
          end
        end
      end

      def self.load_const name
        const_get(name.split("::").reverse.each_with_index.map do |e,i|
          e.split("_").map do |f|
            f.downcase.tap { |o| o[0] = o[0].upcase } + (if i == 0
              "Entity"
            end.to_s)
          end.join
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
        ([ "type" ] + self.class.savable).reduce({}) do |m,v|
          m.merge({ v => h[v]})
        end
      end
    end
  end
end
