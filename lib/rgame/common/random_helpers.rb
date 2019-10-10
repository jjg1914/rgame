# frozen_string_literal: true

module RGame
  module Common
    module RandomHelpers
      module_function

      def random_yield probability
        (rand <= probability).tap { |o| yield if o and block_given? }
      end

      def random_inverse_yield probability
        random_yield(1 - probability) { yield if block_given? }
      end

      def random_list_yield list
        list.sample.tap { |o| yield o if block_given? }
      end

      def random_weights_yield weights
        total_weight = weights.map { |e| e[1] }.sum

        table = weights.map do |e|
          [ e[0], e[1] / total_weight.to_f ]
        end.reduce([]) do |m, v|
          m + [ [ v[0], (m.last&.last).to_f + v[1] ] ]
        end

        value = rand
        table.find { |e| e[1] >= value }.first.tap do |o|
          yield o if block_given?
        end
      end
    end
  end
end
