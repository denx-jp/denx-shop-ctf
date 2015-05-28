require 'open-uri'
require 'cgi'

class ShopController < ApplicationController
  before_action :get_logged_on_user, only: %i(index search register do_logout do_buy)

  def index
    if @user
      redirect_to :search
    else
      redirect_to :login
    end
  end

  def login
  end

  def do_login
    user_id = params[:user_id]
    password = params[:password]
    if User.exists?(user_id: user_id, password: password)
      session_id = create_session_id(user_id)
      UserSession.where(user_id: user_id).delete_all
      UserSession.create!(user_id: user_id, session_id: session_id)
      cookies.permanent[:session_id] = session_id
      flash[:info] = 'ログインしました'
      redirect_to :search
    else
      raise 'login failed'
    end
  rescue
    flash[:error] = 'ログイン失敗'
    redirect_to :login
  end

  def register
  end

  def do_register
    user_id = params[:user_id]
    password = params[:password]
    username = params[:username]
    if user_id.blank? || password.blank? || username.blank?
      raise 'ユーザーID，パスワード，ユーザー名のいずれかが入力されていません'
    end
    if user_id.length > 30 || password.length > 30 || username.length > 30
      raise 'ユーザーID，パスワード，ユーザー名のいずれかが長すぎます（30文字以内にしてください）'
    end
    if user_id.match(/\w+/).nil?
      raise 'ユーザーIDに半角英数字以外の文字列が含まれています'
    end
    if User.exists?(user_id: user_id)
      raise '既に同じユーザーIDが登録されています'
    end
    User.create!(user_id: user_id, name: username, password: password)
    flash[:info] = "ユーザーID: #{user_id}で登録に成功しました"
    redirect_to :login
  rescue => ex
    flash[:error] = ex.message
    redirect_to :register
  end

  def do_logout
    if @user
      UserSession.where(user_id: @user.user_id).delete_all
      flash[:info] = 'ログアウトしました'
    end
    redirect_to :login
  end

  def search
    if params[:keyword].present?
      keyword = CGI.escape(params[:keyword])
      res = open("http://shopping.yahooapis.jp/ShoppingWebService/V1/json/itemSearch?appid=dj0zaiZpPWRGaEE1OGtZTGNNVyZzPWNvbnN1bWVyc2VjcmV0Jng9ZmM-&query=#{keyword}")
      status_code = res.status[0].to_i
      if status_code == 200
        @items = JSON.parse(res.read)["ResultSet"]["0"]["Result"].values.select do |v|
          v.is_a?(Hash) && v.has_key?("Name")
        end
      end
    end
    @histories = History.order("created_at DESC")
  end

  def do_buy
    if @user && params[:jan].present?
      jan = CGI.escape(params[:jan])
      res = open("http://shopping.yahooapis.jp/ShoppingWebService/V1/json/itemSearch?appid=dj0zaiZpPWRGaEE1OGtZTGNNVyZzPWNvbnN1bWVyc2VjcmV0Jng9ZmM-&jan=#{jan}")
      product = JSON.parse(res.read)["ResultSet"]["0"]["Result"]["0"] rescue nil
      History.create!(
        user_id: @user.user_id,
        username: @user.name,
        item_name: product["Name"],
        item_url: product["Url"],
        item_image_url: product["Image"]["Medium"],
        price: product["Price"]["_value"].to_i,
      )
      flash[:info] = "#{product["Name"]}を購入しました！"
    end
    redirect_to :search
  end

  def user_page
    user_id = params[:user_id]
    @user = User.where(user_id: user_id).first
    redirect_to :index unless @user
  end

  private 
  def create_session_id(user_id)
    "#{user_id}_#{Time.current.strftime('%Y_%m_%d')}"
  end

  def get_logged_on_user()
    session_id = cookies[:session_id]
    us = UserSession.where(session_id: session_id).first
    if us
      @user = User.where(user_id: us.user_id).first
    end
  end
end
