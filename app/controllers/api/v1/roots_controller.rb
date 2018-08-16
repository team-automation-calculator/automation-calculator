module Api
  module V1
    class RootsController < Api::V1::ApplicationController
      def show
        head :ok
      end
    end
  end
end
