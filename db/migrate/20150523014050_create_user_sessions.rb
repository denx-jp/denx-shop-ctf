class CreateUserSessions < ActiveRecord::Migration
  def change
    create_table :user_sessions do |t|
      t.string :user_id
      t.string :session_id

      t.timestamps null: false
    end
  end
end
