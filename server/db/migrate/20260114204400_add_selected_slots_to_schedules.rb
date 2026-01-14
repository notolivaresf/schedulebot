class AddSelectedSlotsToSchedules < ActiveRecord::Migration[8.0]
  def change
    add_column :schedules, :selected_slots, :json
  end
end
