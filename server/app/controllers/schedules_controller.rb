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

  def confirm
    @schedule = Schedule.find(params[:id])
    @schedule.confirmed!
    redirect_to @schedule, notice: "Schedule confirmed!"
  end

  def reject
    @schedule = Schedule.find(params[:id])
    @schedule.rejected!
    redirect_to @schedule, notice: "Schedule rejected."
  end

  private

  def schedule_params
    params.require(:schedule).permit(:timezone, slots: [:date, :startTime, :endTime])
  end
end
