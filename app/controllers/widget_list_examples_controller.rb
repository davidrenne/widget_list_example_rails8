class WidgetListExamplesController < ApplicationController
  def administration
    @output = WidgetList.go!
    render json: JSON.parse(@output) if params.key?(:ajax)
  end
end
