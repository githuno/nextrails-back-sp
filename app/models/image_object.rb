class ImageObject < ApplicationRecord
    has_many :images
    # find_or_create_byを作成
    def self.find_or_create_by(id:)
        image_object = find_by(id: id)
        return image_object if image_object.present?
        create(id: id)
    end
end
