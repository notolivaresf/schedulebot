class SchedulesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :select]

  def show
    @schedule = Schedule.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @schedule }
    end
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

  def select
    @schedule = Schedule.find(params[:id])

    update_params = {
      selected_slots: params[:selected_slots]&.map(&:to_unsafe_h),
      status: :confirmed
    }

    if @schedule.update(update_params)
      render json: { success: true, redirect_url: confirmation_schedule_path(@schedule) }
    else
      render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def confirmation
    @schedule = Schedule.find(params[:id])
  end

  private

  def schedule_params
    params.require(:schedule).permit(:timezone, slots: [:date, :startTime, :endTime])
  end
end
