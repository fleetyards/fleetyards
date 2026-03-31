resource :otp, controller: :otp, only: [] do
  collection do
    get :qrcode
    post :start
    post :enable
    post :disable
    post "generate-backup-codes" => "otp#generate_backup_codes"
  end
end
