# frozen_string_literal: true

require "dungeon/core/aspect"

module Dungeon
  module Common
    module RestrictAspect
      def self.normalize_begin_end value
        if value.respond_to?(:end) and value.begin != value.end
          [ value.begin, value.end ]
        else
          [ 0, value.begin ]
        end
      end

      def self.normalize_first_last value
        if value.respond_to?(:last) and value.first != value.last
          [ value.first, value.last ]
        else
          [ 0, value.first ]
        end
      end

      def self.normalize_value value
        if value.respond_to? :begin
          self.normalize_begin_end value
        elsif value.respond_to? :first
          self.normalize_first_last value
        elsif not value.nil?
          [ 0, value ]
        else
          [ nil, nil ]
        end.map do |e|
          e.to_i unless e.nil?
        end.tap do |o|
          o.sort! if o.none?(&:nil?)
        end
      end

      def self.restrict_value value, restrict_value
        unless restrict_value.nil?
          if not restrict_value.first.nil? and value < restrict_value.first
            restrict_value.first - value
          elsif not restrict_value.last.nil? and value > restrict_value.last
            restrict_value.last - value
          end
        end.to_i
      end

      include Dungeon::Core::Aspect

      attr_reader :x_restrict
      attr_reader :y_restrict

      on :post_collision do
        restrict_mtv = [
          RestrictAspect.restrict_value(x, x_restrict),
          RestrictAspect.restrict_value(y, y_restrict),
        ]

        if restrict_mtv.any? { |e| e != 0 }
          self.emit(:collision, nil, restrict_mtv)
        end
      end

      def x_restrict= value
        @x_restrict = RestrictAspect.normalize_value value
      end

      def y_restrict= value
        @y_restrict = RestrictAspect.normalize_value value
      end

      def to_h
        super.merge({
          "x_restrict" => self.x_restrict,
          "y_restrict" => self.y_restrict,
        })
      end
    end
  end
end
