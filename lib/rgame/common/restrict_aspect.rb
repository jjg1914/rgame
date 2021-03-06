# frozen_string_literal: true

require "rgame/core/aspect"
require "rgame/core/collision"

module RGame
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

      def self.restrict_value low, high, restrict_value
        unless restrict_value.nil?
          if not restrict_value.first.nil? and low < restrict_value.first
            restrict_value.first - low
          elsif not restrict_value.last.nil? and high > restrict_value.last
            restrict_value.last - high
          end
        end.to_i
      end

      include RGame::Core::Aspect

      attr_reader :x_restrict
      attr_reader :y_restrict

      on "add" do
        self.x_restrict = self.parent.width
        self.y_restrict = self.parent.height
      end

      on :collision_sweep do
        info = RGame::Core::Collision::ReverseCollisionInfo.new self, {
          "left" => @x_restrict&.first || -Float::INFINITY,
          "right" => @x_restrict&.last || Float::INFINITY,
          "top" => @y_restrict&.first || -Float::INFINITY,
          "bottom" => @y_restrict&.last || Float::INFINITY,
        }

        if info.time < 1
          self.emit(:collision, nil, info) if info.time < 1
        elsif info.mtv.any? { |e| not e.zero? and e.finite? }
          self.x += info.mtv[0] if info.mtv[0].finite?
          self.y += info.mtv[1] if info.mtv[1].finite?
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
