class Chapter::Officer < ActiveRecord::Base
  belongs_to :dke_info, class_name: "User::Brother::DkeInfo"
  has_many :public_pages
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  
  #Override of original init method
  #@param params: dictionary of attributes
  #@param transfer: boolean, should only be true when used in Transfer model
  #@note: the purpose of this override is to automatically set position
  #@return boolean
  def initialize(params = {}, transfer = false)
    super(params)
    self.position = Chapter::Officer.maximum("position") + 1 unless transfer
  end
  
  #Override of valid? method to check that contact and disp are set correctly
  #@return boolean
  def valid?(params = {})
    if super(params)
      if self.disp && self.contact.empty?
        self.errors.add(:contact, "can't be blank and displayed")
        return false
      else
        return true
      end
    else
      return false
    end
  end
  
  ##########################Static Methods############################
  
  #generates list of contact information based on the value of disp
  #@return Hash of selected officers
  def self.contact_info
    officers = Hash.new
    position_map =  self.where(disp: 1).order(:position)
    position_map.each do |pos|
      if pos.dke_info
        name = pos.dke_info.brother.full_name
        year = pos.dke_info.brother.mit_info.year.to_s[2..3]
        if pos.email.blank?
          email = "#{pos.dke_info.brother.user.uname}@mit.edu"
        else
          email = pos.email
        end
        officers[pos.name] = {name: pos.title, 
                                  full_name: name, 
                                  year: year, 
                                  contact: pos.contact, 
                                  email: email}
      end
    end
    return officers
  end
  
  #generates a list of all officers for the index page
  #@return Hash of officers
  def self.list_all
    officers = []
    position_map =  self.select("id, position, name, dke_info_id, contact, disp, title").order(:position)
    position_map.each do | pos |
      begin
        name = pos.dke_info.brother.full_name
        year = pos.dke_info.brother.mit_info.year.to_s[2..3]
      rescue
        name = ""
        year = ""
      end
      officers << {id: pos.id,
                   name: pos.name,
                   title: pos.title,
                   full_name: name,
                   year: year,
                   pos: pos.position, 
                   disp: pos.disp,
                   contact: pos.contact}
    end
    return officers
  end
  
  #method to update all officers after elections
  #@param params: dictionary of officers and holders ( {officer.id: brother.dke_info.id})
  def self.mass_update(params)
    params.each do | id, dke_info_id |
      self.find(id).update_attributes({dke_info_id: dke_info_id})
    end
  end
  
  #updates ordering on index and contact pages & disp parameter
  #@param params: dictionary of officers and position ({officer.id: {disp: disp, position: position}})
  def self.update_contacts(params)
    params.each do | id, fields |
      if id =~ /\A\d+\z/
        unless self.find(id).update_attributes(params.require(id).permit(:disp, :position))
          return false
        end
      end
    end
    return true
  end
  
end