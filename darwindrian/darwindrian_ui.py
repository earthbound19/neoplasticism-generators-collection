#GUI module of Darwindrian.
#API used: java Swing/awt
#Author: Jian Yin Shen

from javax import swing
from java import awt
from java import io
from java.awt import geom
from java.awt import image
from java.awt.event import *
from javax.imageio import ImageIO
from java.lang import String
from java.lang import System
from darwindrian_geom import *
from darwindrian_controller import *

generation_history = []
graph_history = []

class MiniView(swing.JScrollPane, swing.event.ListSelectionListener):
	
	class __Renderer(swing.ListCellRenderer):
		def __init__(self):
			pass
			
		def getListCellRendererComponent(self, ls, value, index, selected, cellHasFocus):
			#Wrapper pane
			wrapper = swing.JPanel(layout = awt.FlowLayout(awt.FlowLayout.CENTER))
			wrapper.add(value)
			wrapper.preferredSize = awt.Dimension(100,90)
			
			if selected:
				wrapper.background = awt.Color.GRAY
			
			value.gray_scale = 1 #selected
			return wrapper
	
	class __MiniMondrian(swing.JPanel):
		def __init__(self, graph):
			swing.JPanel.__init__(self)
			self.preferredSize = awt.Dimension(80,80)
			self.background = WHITE
			self.__graph = graph
			self.gray_scale = 0
			
		def paint(self,g):
			swing.JPanel.paint(self, g)
			
			canvas_x = float(gui_canvas.preferredSize.width)
			canvas_y = float(gui_canvas.preferredSize.height)
			mini_x = float(self.preferredSize.width)
			mini_y = float(self.preferredSize.height)
			g.scale(mini_x/canvas_x, mini_y/canvas_y)
			
			for r in self.__graph.rectangles:
				
				if self.gray_scale:
					g.setColor(r[1])
				else:
					g.setColor(awt.Color.LIGHT_GRAY)
				g.fill(r[0])
				#draw lines
				#g.setStroke(self.__line_stroke)
			for l in self.__graph.lines:
				g.setColor(BLACK)
				g.draw(l)
			
			
	def __init__(self):
		swing.JScrollPane.__init__(self)
		self.__listModel = swing.DefaultListModel()
		self.__list = swing.JList(self.__listModel)
		self.__list.cellRenderer = self.__Renderer()
		self.__list.addListSelectionListener(self)
		
		self.setViewportView(self.__list)
		
		
	def add_mini_view(self, graph):
		mini = self.__MiniMondrian(graph)
		self.__listModel.addElement(mini)
		self.__list.setSelectedIndex(0)#(self.__listModel.size()-1)
	
	def clear(self):
		self.__listModel.clear()
		
	def valueChanged(self, e):
		self.__display_selected()
		
	def __display_selected(self):
		index = self.__list.getSelectedIndex()
		if index < 0:
			graph = None
		else:
			graph = graph_history[index]

			gui_control.stru.selected = graph.chromosome.structure_prefer
			gui_control.co.selected = graph.chromosome.color_prefer
			gui_control.both.selected = graph.chromosome.structure_prefer and graph.chromosome.color_prefer
			gui_control.none.selected = (not graph.chromosome.structure_prefer) and (not graph.chromosome.color_prefer)
			gui_canvas.set_graph(graph)
		
class Canvas(swing.JPanel):
	'''GUI component which is responsible for rendering pictures'''
			
	class NameFileFilter(swing.filechooser.FileFilter):
		def getDescription(self):
			return "PNG file"
		def accept(self, file):
			name = file.getName()
			return name.lower().find('.png' ) <> -1 or file.isDirectory()
			
	class TxtFileFilter(swing.filechooser.FileFilter):
		def getDescription(self):
			return "txt file"
		def accept(self, file):
			name = file.getName()
			return name.lower().find('.txt' ) <> -1 or file.isDirectory()
			
	def __init__(self):
		swing.JPanel.__init__(self)
		global mondrian_instance
		self.preferredSize = awt.Dimension(480,480)
		self.background = WHITE
		self.__line_stroke = awt.BasicStroke(9)
		self.__rec_stroke = awt.BasicStroke()
		self.__load_popup_menu()
		self.__current_graph = None
		
	def set_graph(self, graph):
		self.__current_graph = graph
		self.repaint()
	
	def get_graph(self):
		return self.__current_graph
		
	def paint(self,g):
		swing.JPanel.paint(self,g)
		
		if self.__current_graph == None:
			return
			
		#draw rectangles
		g.setStroke(self.__rec_stroke)
		for r in self.__current_graph.rectangles:
			g.setColor(r[1])
			g.fill(r[0])
		#draw lines
		g.setStroke(self.__line_stroke)
		for l in self.__current_graph.lines:
			g.setColor(BLACK)
			g.draw(l)
			
	def save_as(self):
		jc = swing.JFileChooser()
		fl = self.NameFileFilter()
		jc.setFileFilter(fl)
		jc.setSelectedFile(io.File('p'+str(graph_history.index(self.__current_graph)+1)+'.png'))
		resp = jc.showSaveDialog(self)
		if resp == swing.JFileChooser.APPROVE_OPTION:
			self.__output_image(jc.getSelectedFile())
	
	def save_all(self):
		global graph_history
		
		jc = swing.JFileChooser()
		jc.setFileSelectionMode(swing.JFileChooser.DIRECTORIES_ONLY)
		resp = jc.showSaveDialog(self)
		if resp == swing.JFileChooser.APPROVE_OPTION:
			count = 1
			for graph in graph_history:
				file_name = "p"+str(count)+".png"
				self.set_graph(graph)
				self.__output_image(io.File(jc.getSelectedFile().getAbsolutePath()+'/'+file_name))
				count = count+1
			
	def dump_data(self):
		
		#Popup dialogs
		jc = swing.JFileChooser()
		fl = self.TxtFileFilter()
		jc.setFileFilter(fl)
		resp = jc.showSaveDialog(self)
		if resp == swing.JFileChooser.APPROVE_OPTION:
			self.__output_raw_data(jc.getSelectedFile())
	
	def __output_raw_data(self, f):
		global graph_history
		#Use python impl
		path = f.getAbsolutePath()
		_file = open(path, 'w')
		
		number = 1
		generation_number = 1
		for graph_history in generation_history:
		  	_file.write("generation: ")
			_file.write(str(generation_number))
			_file.write('\n')
			for graph in graph_history:
				_file.write("graph: ")
				_file.write(str(number))
				_file.write('\n')
			
				for line in graph.lines:
					_file.write("line: ")
					_file.write(str(line.getX1())+' ')
					_file.write(str(line.getY1())+' ')
					_file.write(str(line.getX2())+' ')
					_file.write(str(line.getY2())+'\n')
			
				for rec in graph.rectangles:
					_file.write("Rectangle: ")
					_file.write(str(rec[0].getX())+' ')
					_file.write(str(rec[0].getY())+' ')
					_file.write(str(rec[0].getWidth())+' ')
					_file.write(str(rec[0].getHeight())+'\n')
				
					_file.write("color(RGB): ")
					_file.write(str(rec[1].getRed())+' ')
					_file.write(str(rec[1].getGreen())+' ')
					_file.write(str(rec[1].getBlue())+'\n')
				number = number + 1
				_file.write('\n\n')
			generation_number = generation_number + 1
		
		_file.close()
	
	def __output_image(self, f):
		out = io.FileOutputStream(f)
		size = self.preferredSize
		im = image.BufferedImage(size.width, size.height, image.BufferedImage.TYPE_INT_RGB)
		g2d = im.getGraphics()
		self.paint(g2d)
		ImageIO.write(im,'png',out)
		out.close()
		gui_status_bar.show_message("Image saved.")
		
	def __load_popup_menu(self):
		self.popup = swing.JPopupMenu()
		self.__saveas_b = swing.JMenuItem('Save as PNG...')
		self.popup.add(self.__saveas_b)
		
		self.__dump_data = swing.JMenuItem("Dump raw data as txt...")
		self.popup.add(self.__dump_data)

		controller.add_mouse_action(self, self.__popingup, 'Clicked')
		
		controller.add_action(self.__saveas_b, self.save_as)
		controller.add_action(self.__dump_data, self.dump_data)
		
	def __popingup(self, e):
		if e.getButton() == MouseEvent.BUTTON3 and self.__current_graph <> None:
			self.popup.show(e.getComponent(), e.getX(), e.getY())
					
class ControlPane(swing.JPanel):
	'''Contains GUI control elements'''
	def __init__(self):
		swing.JPanel.__init__(self)
		self.layout = awt.FlowLayout(awt.FlowLayout.RIGHT)
		
		self.__next_b = swing.JButton('See next generation')
		self.add(swing.JLabel("Like: "))
		self.__group = swing.ButtonGroup()
		
		#radio buttons
		def rb(text, _self = self):
			b = swing.JRadioButton(text)
			b.setActionCommand(text)
			return b
		
		self.stru = rb('Structure')
		self.co = rb('Color')
		self.both = rb('Both')
		self.none = rb('None')
		self.__r_options = (self.stru, self.co, self.both, self.none)

		for b in self.__r_options:
			self.add(b)
			self.__group.add(b)
			controller.add_action(b, self.__like_config, b)

		self.add(self.__next_b)
		controller.add_action(self.__next_b, self.next_paint)
		
	def __like_config(self, source):
	  chromosome = gui_canvas.get_graph().chromosome
	  chromosome.structure_prefer = 0
	  chromosome.color_prefer = 0
	  chromosome.fitness = 0.5

	  if source == self.stru:
	    chromosome.structure_prefer = 1
	    chromosome.fitness += 0.25

	  elif source == self.co:
	    chromosome.color_prefer = 1
	    chromosome.fitness += 0.15

	  elif source == self.both:
	    chromosome.structure_prefer = 1
	    chromosome.color_prefer = 1
	    chromosome.fitness += 0.5

	  elif source == self.none:
	    chromosome.fitness -= 0.2

	  print "rated fitness: ", chromosome.fitness

				
	def next_paint(self):
	  	gui_clear_graph()
		global graph_history
		global generation_history
		i = 0
		gui_status_bar.show_message("Generating pictures, please wait....")

		batch = evolution.next_generation()
		for chromosome in batch:
			graph = mondrian_instance.compose(chromosome, gui_canvas.preferredSize)
			gui_next_graph(graph)
		generation_history.append(graph_history)
	
	def enable_rating(self, enable):
		for b in self.__r_options:
			b.setEnabled(enable)

#This class must be instanized after all other gui elements
class ControlMenu(swing.JMenuBar):
	def __init__(self):
		swing.JMenuBar.__init__(self)
		
		#init menus
		m_file = swing.JMenu("File")
		self.mi_save_as = swing.JMenuItem("Save as PNG...")
		controller.add_action(self.mi_save_as, gui_canvas.save_as)
		
		self.mi_dump_data = swing.JMenuItem("Dump data as txt...")
		controller.add_action(self.mi_dump_data, gui_canvas.dump_data)
		
		self.mi_save_all = swing.JMenuItem("Save all as PNG...")
		controller.add_action(self.mi_save_all, gui_canvas.save_all)
		
		sp = swing.JSeparator()
		
		mi_exit = swing.JMenuItem("Exit")
		controller.add_action(mi_exit, System.exit, 0)
		
		for m in (self.mi_save_as, self.mi_save_all, self.mi_dump_data, sp, mi_exit):
			m_file.add(m)
		
		m_evolution = swing.JMenu("Evolution")
		mi_reset = swing.JMenuItem("Reset evolution")
		controller.add_action(mi_reset, gui_clear_generation)
		
		mi_next = swing.JMenuItem("Next generation")
		controller.add_action(mi_next, gui_control.next_paint)
		sp = swing.JSeparator()
		
		mi_info = swing.JMenuItem("Set mutation on")
		def mutation_toggle(menu = mi_info):

		  evolution.mutation = not evolution.mutation
		  if evolution.mutation:
		    mi_info.text = "Set mutation off"
		  else:
		    mi_info.text = "Set mutation on"


		controller.add_action(mi_info, mutation_toggle)

		for m in (mi_reset, mi_next, sp, mi_info):
			m_evolution.add(m)
			
		m_about = swing.JMenu("Help")
		mi_about = swing.JMenuItem("About Darwindrian")
		for m in [mi_about]:
			m_about.add(m)
		
		for m in (m_file, m_evolution, m_about):
			self.add(m)
		
class StatusBar(swing.JTextField):
	def __init__(self):
		swing.JTextField.__init__(self)
		self.editable = 0
		
	def show_message(self, txt):
		self.text = txt
	
	def clear_message():
		self.show_message("")
		

#static methods about interface control

def gui_enable_save(enable):
	gui_menu.mi_save_as.enabled = enable
	gui_menu.mi_save_all.enabled = enable
	gui_menu.mi_dump_data.enabled = enable

def gui_clear_generation():
	global generation_history
	generation_history = []
	gui_clear_graph()
	evolution.reset_generation()

def gui_clear_graph():
	global graph_history
	global generation_history

	#generation_history.append(graph_history)
	
	graph_history = []
	gui_mini_view.clear()
	gui_canvas.set_graph(None)
	gui_control.enable_rating(0)
	gui_status_bar.show_message("Click 'see next' to evolute graphs.")
	gui_enable_save(0)

def gui_next_graph(graph):
	global graph_history
	graph_history.append(graph)
	gui_mini_view.add_mini_view(graph)
	gui_canvas.set_graph(graph_history[0])
	gui_control.enable_rating(1)
	gui_status_bar.show_message("New generation.")
	gui_enable_save(1)

		
#global GUI instance
gui_canvas = Canvas()
gui_control = ControlPane()
gui_mini_view = MiniView()
gui_status_bar = StatusBar()
gui_menu = ControlMenu()


