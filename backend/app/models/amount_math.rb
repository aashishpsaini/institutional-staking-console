# frozen_string_literal: true

# Token amounts are stored as base-unit integer strings (wei, lamports). Values
# like 32 ETH = 3.2e19 wei overflow SQLite's 64-bit INTEGER, so sums are done
# with Ruby's arbitrary-precision Integer instead of SQL SUM(). On Postgres a
# NUMERIC(78,0) column with SQL aggregation would be the next step.
module AmountMath
  INTEGER_STRING = /\A\d+\z/

  module_function

  def sum(amounts)
    amounts.sum(0) { Integer(_1, 10) }.to_s
  end

  def sum_by(pairs)
    pairs.each_with_object(Hash.new(0)) { |(key, amount), totals| totals[key] += Integer(amount, 10) }
         .transform_values(&:to_s)
  end
end
