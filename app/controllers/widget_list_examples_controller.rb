class WidgetListExamplesController < ApplicationController
  def administration
    @output = WidgetList.go!
    render json: JSON.parse(@output) if params.key?(:ajax) || params.key?(:BUTTON_VALUE)
  end
end
