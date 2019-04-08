module Dungeon
  module Core
    module DynamicScope
      def self.scope
        (@scope ||= {})
      end

      def var_defined? name
        DynamicScope.scope.has_key?(name.to_s) and
          not DynamicScope.scope[name.to_s].empty?
      end

      def let_var name, value
        let_vars({ name => value }) { yield if block_given? }
      end

      def get_var name
        get_vars([ name ]).first
      end

      def let_vars vars
        vars.each do |e|
          unless DynamicScope.scope.has_key?(e[0].to_s)
            DynamicScope.scope[e[0].to_s] = []
          end
          DynamicScope.scope[e[0].to_s].push e[1]
        end

        begin
          yield if block_given?
        ensure
          vars.keys.each { |e| DynamicScope.scope[e.to_s].pop }
        end
      end

      def get_vars vars
        vars.map do |e|
          unless var_defined? e
            raise ArgumentError.new("not defined %s" % e.inspect)
          end

          DynamicScope.scope.fetch(e.to_s, []).last
        end
      end
    end
  end
end
