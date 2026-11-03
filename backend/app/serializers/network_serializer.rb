# frozen_string_literal: true

module NetworkSerializer
  module_function

  def call(network)
    { slug: network.slug, display_name: network.display_name, symbol: network.symbol, decimals: network.decimals }
  end
end
