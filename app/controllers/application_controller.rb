# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ErrorHandling
  include Authentication::Authenticatable
end
