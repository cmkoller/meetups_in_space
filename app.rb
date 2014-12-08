require 'Dotenv'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

Dotenv.load

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end

end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

def is_member?(meetup_id, user_id)
  if signed_in?
    !Membership.where(["user_id = ? and meetup_id = ?", user_id, meetup_id]).empty?
  end
end


get '/' do
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"
  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end

get '/meetup/:id' do
  @meetup = Meetup.find(params[:id])
  erb :meetup
end

post '/meetup/:id' do
  if params[:leave]
    membership = Membership.where('user_id = ? AND meetup_id = ?', session[:user_id], params[:id]).first
    membership.destroy
    flash[:notice] = "You\'ve successfully left #{Meetup.find(params[:id]).name}!"

  elsif params[:title]
    Comment.create(user_id: session[:user_id], meetup_id: params[:id],
      title: params[:title], body: params[:body])
  elsif params[:join] && signed_in?
    Membership.create(user_id: session[:user_id], meetup_id: params[:id])
    flash[:notice] = "You\'ve successfully joined #{Meetup.find(params[:id]).name}!"
  elsif params[:join]
    flash[:notice] = "You must sign into join a meetup!"
  end
  redirect "/meetup/#{params[:id]}"
end

get '/new' do
  unless signed_in?
    authenticate!
  end
  erb :new
end

post '/new' do
  flash[:notice] = 'You\'ve successfully created a meetup!'
  meetup = Meetup.create(params)
  redirect "/meetup/#{meetup.id}"
end
