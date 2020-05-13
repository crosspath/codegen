class User < ApplicationRecord
  authenticates_with_sorcery!

  validates :email, format: /\A[^@]+@[^@]+\z/
  validates :password, presence: true, on: :create
  validates :password, length: 6..30, allow_nil: true

  def reload
    super
    self.password = nil
  end
end
