class SchedulesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def show
    @schedule = Schedule.find(params[:id])
  end

  def create
    @schedule = Schedule.new(schedule_params)

    if @schedule.save
      render json: {
        id: @schedule.id,
        url: schedule_url(@schedule)
      }, status: :created
    else
      render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def schedule_params
    params.require(:schedule).permit(:timezone, slots: [:date, :startTime, :endTime])
  end
end
