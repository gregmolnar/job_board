module Otp
  def self.unsign(signature, max_age)
    nobi = Nobi::TimestampSigner.new('my secret here')

    begin
      company_id = nobi.unsign(signature, max_age: max_age)
      Company[company_id]
    rescue Nobi::BadData
    end
  end
end