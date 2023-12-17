require "csv"

class ImportCsv
  def self.execute(model:, file_name: nil)
    model_name = model.to_s.classify
    table_name = model_name.tableize
    file_name ||= table_name.singularize
    path = Rails.root.join("db/csv_data/#{file_name}.csv")

    list = []
    CSV.foreach(path, headers: true) do |row|
      list << row.to_h
    end
    # 与えられたモデルに CSVデータを投入
    model_name.constantize.import!(list, on_duplicate_key_update: { conflict_target: [:id] })

    # 次に振る id を正常化
    if model_name.constantize.columns_hash["id"].type == :integer || model_name.constantize.columns_hash["id"].type == :serial
        ActiveRecord::Base.connection.execute("select setval('#{table_name}_id_seq',(select max(id) from #{table_name}))")
    end
        
  end
end