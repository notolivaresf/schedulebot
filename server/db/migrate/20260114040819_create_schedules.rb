class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.json :slots
      t.string :timezone
      t.string :status, default: "pending", null: false

      t.timestamps
    end
  end
end
