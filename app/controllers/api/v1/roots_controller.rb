module API
  module V1
    class RootsController < API::V1::ApplicationController
      def show
        head :ok
      end
    end
  end
end
