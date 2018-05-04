from java import awt

class GlobalController:
	
	class DummyAction(awt.event.ActionListener):
		def __init__(self, target_method, parameters):
			self.__target = target_method
			self.__parameters = parameters
			
		def actionPerformed(self, e):
			self.__target(*self.__parameters)
	
	class DummyMouseAction(awt.event.MouseAdapter):
		'''action type: Clicked/Entered/Exited/Pressed/Released'''
		def __init__(self, target_method, action_type, parameters):
			awt.event.MouseAdapter.__init__(self)
			self.__target = target_method
			self.__action_type = action_type
			self.__parameters = parameters
			#Dynamic delegation
			setattr(self, 'mouse'+action_type, self.__delegate_to)
			
		def __delegate_to(self, event):
			self.__target(event, *self.__parameters)
		
		#Jython bug:
		#static definition must present or dynamic delegation won't work
		def mouseClicked(self, f):
			raise 'should never be called'
			
	#Inner class definition done		
	
	def add_action(self, source, method, *para):
		a = GlobalController.DummyAction(method, para)
		source.addActionListener(a)
		
	def add_mouse_action(self, source, method, action_type, *para):
		m = GlobalController.DummyMouseAction(method, action_type, para)
		source.addMouseListener(m)
		
	def __init__(self):
		pass
	
controller = GlobalController()
