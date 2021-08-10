class CheckoutController < ApplicationController
  def create
    order = Order.find(params[:order_id])
    articles_per_price = order.articles.joins(:category)
                              .select('categories.stripe_pricing_id, articles.id, articles.title')
                              .group_by(&:stripe_pricing_id)
    pricing_list = articles_per_price.map do |key, value|
      { price: key, quantity: value.size, description: value.pluck(:title).join(', ') }
    end

    session = Stripe::Checkout::Session.create(
      {
        payment_method_types: ['card'],
        line_items: pricing_list,
        mode: 'payment',
        success_url: articles_url,
        cancel_url: order_url(order)
      }
    )
    order.update!(stripe_payment_id: session.payment_intent)
    redirect_to session.url
  end
end