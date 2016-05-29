e2function void entity:setPropVelocity( vector velocity )
  if(not (this and this:IsValid())) then return end
  local phys = this:GetPhysicsObject()
  if IsValid( phys ) then
    phys:SetVelocity(Vector(velocity[1], velocity[2], velocity[3]))
  end
end

e2function void entity:setPropVelocityInstant( vector velocity )
  if(not (this and this:IsValid())) then return end
  local phys = this:GetPhysicsObject()
  if IsValid( phys ) then
    phys:SetVelocityInstantaneous(Vector(velocity[1], velocity[2], velocity[3]))
  end
end