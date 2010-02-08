class CreateQuips < ActiveRecord::Migration
  def self.up
    create_table :quips do |t|
      t.string :source
      t.string :submitter
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :quips
  end
end
