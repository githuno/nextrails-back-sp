class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_many_attached :file, dependent: :destroy # 画像ファイルの他、html、mp4もアップロードする

  def self.upload(object_id, user_id, data, now) # インスタンス生成も行うのでクラスメソッドとして定義
    begin
      # DBに登録
      filename = "#{now}.png"
      key = "#{object_id}/#{filename}"
      image_path = "#{ENV['S3_PUBLIC_URL']}/#{key}"
      image = Image.create!(object_id: object_id, image_path: image_path, updated_by: user_id) 
      # S3にアップロード
      bytes = Base64.decode64(data)
      io = StringIO.new(bytes)
      image.file.attach(io: io, key: key, filename: filename, content_type: 'image/png')
      image # return
    rescue StandardError => e
      raise "Failed to upload image: #{e.message}"
    end
  end

  def delete # 既にインスタンス化したものを削除するのでインスタンスメソッドとして定義
    @object = ImageObject.find_by(id: object_id)
    S3ResourceService.instance.delete_related(self) # アタッチしていない関連ファイルも削除する
    file.purge if file.attached?
    destroy
    @object.destroy if @object.images.empty?
  end

  def basename # 既にインスタンス化したものからファイル名を取得するのでインスタンスメソッドとして定義
    image_path.split('/').last.sub(/\.[^.]+\z/, '')
  end
end