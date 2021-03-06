class CardsController < ApplicationController
  require "payjp"
  before_action :set_card

  def new
    if user_signed_in?
      card = Card.where(user_id: current_user.id)
      redirect_to users_path(current_user.id) if card.exists?
    else
      redirect_to user_session_path
    end
  end

  def pay #payjpとCardのデータベース作成
    Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_SECRET_KEY]
    #保管した顧客IDでpayjpから情報取得
    if params['payjp_token'].blank?
      redirect_to new_card_path
    else
      customer = Payjp::Customer.create(
        card: params['payjp_token'],
        metadata: {user_id: current_user.id}
      ) 
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
    
      if @card.save
        redirect_to card_path(current_user.id)
      else
        redirect_to pay_cards_path
      end
    end
  end

  def destroy
    if @card.present?
      Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_SECRET_KEY]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      customer.delete
      @card.delete
    end
      redirect_to users_path(current_user)
  end

  def show #Cardのデータpayjpに送り情報を取り出す
    if @card.blank?
      redirect_to new_card_path 
    else
      Payjp.api_key = Rails.application.credentials.payjp[:PAYJP_SECRET_KEY]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @default_card_information = customer.cards.retrieve(@card.card_id)
    end
  end

  def set_card
    @card = Card.find_by(user_id: current_user.id)
  end

end
