function EFFECT:Init( data )
	self.data = data
	self.particles = 4
end

function EFFECT:Think()
	return true
end

function EFFECT:Render()
	local vOffset = self.data:GetOrigin() + Vector( 0, 0, 0.2 )
	local vAngle = self.data:GetAngles()
	
	local emitter = ParticleEmitter( vOffset, false )
		for i=0, self.particles do
			local particle = emitter:Add( "[5]black_hole_micro_b", vOffset )
			if particle then
				particle:SetAngles( vAngle )
				particle:SetVelocity( Vector( 0, 0, 15 ) )
				particle:SetColor( 255, 102, 0 )
				particle:SetLifeTime( 0 )
				particle:SetDieTime( 0.2 )
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 1.6 )
				particle:SetStartLength( 1 )
				particle:SetEndSize( 1.2 )
				particle:SetEndLength( 4 )
			end
		end
	emitter:Finish()
end