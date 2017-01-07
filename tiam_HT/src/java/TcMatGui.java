import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.GridLayout;
import java.awt.Image;
import java.awt.Toolkit;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemListener;
import java.awt.image.BufferedImage;
import java.awt.image.MemoryImageSource;
import java.awt.image.WritableRaster;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.sql.Timestamp;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Date;

import javax.swing.BorderFactory;
import javax.swing.BoxLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTextField;

/**
 * This is the GUI for TC-MAT: the T Cell Motility Analysis Tool
 * @author willie
 */

public class TcMatGui extends JFrame {
	
	private Video video;
	JPanel output;
	private JButton opt1;
	private JButton opt2;
	private JButton opt3;
	private JLabel prompt;
	private JLabel imageLabel;
	private JLabel imageLabel2;
	private JLabel algoMessage;

	public int optChoice = 0;

	
	/**
	 * Construct TcMatGUi
	 */
	public TcMatGui(String tcmatPath) {
		
		//all the panels for the GUI are created in initGui() method
		initGui();
		
		//call the follow methods to create a frame
		setSize(1000,590);
		setTitle("TIAM: the Tool for Integrative Analysis of Motility");
		setDefaultCloseOperation(DISPOSE_ON_CLOSE);
		setVisible(true);
		
		// Welcome User
		welcomeToTcmat();
		
		//get video/experiment information from user
		video = initVideo(tcmatPath);
	}
	
	/**
	 * this method gets user input about the video the be analyzed and makes Video object
	 */
	private Video initVideo(String tcmatPath) {
		//make a pop-up box with instructions 
		//and maybe input check boxes and such for user input on experiment information
		
		// choose folder containing image files (a "video folder")
		boolean pickedDir = false;
		File imgFolder = null;
		while(!pickedDir) {
			JFileChooser fc = new JFileChooser();
			fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
			fc.setDialogTitle("Select Image Directory");
			fc.setCurrentDirectory(new File(tcmatPath));
			fc.showOpenDialog(this);
			imgFolder = fc.getSelectedFile();
			if (imgFolder == null) {
				JOptionPane.showMessageDialog(this, "You must select a video folder.", "Oops...", JOptionPane.ERROR_MESSAGE);
				pickedDir = false;
			} else {
				pickedDir = true;
			}
		}
		
		// the following is a sequence of input dialog boxes to get: name, numChannels, requestedData, and make the channelArray (for each type of data requested)
		
		// get name
		String name = "Video";
		name = JOptionPane.showInputDialog(this,"Enter a name for this analysis.", "myTCellExperiment");
		// get number of channels
		int numChan = 0;
		String numChannels = null;
		while (numChan < 1 || numChan > 10) { 
			numChannels = JOptionPane.showInputDialog(this,"Enter the number of channels for this video.", "4");
			try {
				numChan = Integer.parseInt(numChannels);
			} catch (NumberFormatException e) {
				JOptionPane.showMessageDialog(this, "You must enter a number value for this field. E.g. 4.", "Oops...", JOptionPane.ERROR_MESSAGE); 
			}
		}
		// get position (order) of DIC channel
		int dicChan = 0;
		String dicString = null;
		while (dicChan < 1 || dicChan > numChan) { 
			dicString = JOptionPane.showInputDialog(this,"Enter the position of the DIC channel within the " + numChannels + " channels.", "4");
			if (dicString == null) {
				JOptionPane.showMessageDialog(this, "You must enter a valid number value for this field. E.g. 4.", "Oops...", JOptionPane.ERROR_MESSAGE);
			} else { 
				try {
					dicChan = Integer.parseInt(dicString);
				} catch (NumberFormatException e) {
					JOptionPane.showMessageDialog(this, "You must enter a valid number value for this field. E.g. 4.", "Oops...", JOptionPane.ERROR_MESSAGE); 
				}
			}
		}
			
		// add channels to channelArray, the rest of the channels are assigned irrelevant/initiation value of -1.
		int[] channelArray = {dicChan,-1,-1,-1,-1}; //{dicChan,irmChan,fluorChan1,fluorChan2,outlineChan}
		// return new Video
		return new Video(name,imgFolder.getAbsolutePath(),numChan,channelArray);
	}
	
	/**
	 * this method builds the panels that comprise the GUI
	 */
	public void initGui() {
		//set up main GUI panel
		JPanel mainPanel = (JPanel) getContentPane();
		//split panel vertically
		JSplitPane splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, getButtonPanel(), getOutputPanel());
		//set location of divider
		splitPane.setDividerLocation(550);
		mainPanel.setLayout(new BorderLayout());
		mainPanel.add(splitPane, BorderLayout.CENTER);
	}
	
	/**
	 * This method creates a panel showing images in a grid layout
	 * @return a scroll pane with all the buttons
	 */
	public JScrollPane getButtonPanel() {
		
		// to display decimals in good format
		final DecimalFormat df2 = new DecimalFormat("0.00");
		
		//create a button panel with a grid layout
		JPanel buttonPanel = new JPanel();
		buttonPanel.setLayout(new BoxLayout(buttonPanel, BoxLayout.Y_AXIS));
		
		//add imageLabel to buttonPanel
		ImageIcon imgicon = new ImageIcon("tcell.jpg");
		// ImageIcon imgicon = new ImageIcon(image);
		imageLabel = new JLabel(imgicon);
		imageLabel.setVisible(true);
		imageLabel.setOpaque(true);
		imageLabel.setSize(500,500);
		imageLabel.setPreferredSize(new Dimension(500,500));
		imageLabel.setLocation(500,500);
		buttonPanel.add(imageLabel);
		buttonPanel.revalidate();
		buttonPanel.repaint();
		
		//add imageLabel2 to buttonpanel
			// make this invisible for now
		ImageIcon imgicon2 = new ImageIcon("tcell.jpg");
		imageLabel2 = new JLabel(imgicon);
		imageLabel2.setOpaque(true);
		imageLabel2.setSize(500,500);
		imageLabel2.setPreferredSize(new Dimension(500,500));
		imageLabel2.setLocation(500,1000);
		imageLabel2.setVisible(false);
		buttonPanel.add(imageLabel2);
		buttonPanel.revalidate();
		buttonPanel.repaint();
		
		//add the panel to JScrollPane to make it scrollable
		JScrollPane buttonPane = new JScrollPane(buttonPanel);
		//add border to panel
		buttonPane.setBorder(BorderFactory.createTitledBorder("T Cell Detection Image"));
		return buttonPane;
	}
	
	
	/**
	 * create a panel to show the user instructions and option buttons 
	 * @return a jpanel showing the user instructions and option buttons
	 */
	public JScrollPane getOutputPanel() {
		//set up panel layout (using BoyLayout)
		output = new JPanel();
		output.setLayout(new BoxLayout(output, BoxLayout.Y_AXIS));
		
		// to display decimals in good format
		final DecimalFormat df2 = new DecimalFormat("0.00");
		
		//add user instruction prompt to output panel
		prompt = new JLabel("<html><br><u>User Instructions:</u><br><br>");
		prompt.setVisible(true);
		output.add(prompt);
		
		//add "Option 1" button to output panel
		opt1 = new JButton("Option 1");
		//add another actionlistener to a clear button
		opt1.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				optChoice = 1;
				repaint();
			}	
		});
		//set "Option 1" button size
		opt1.setMinimumSize(new Dimension(400, 70));
		opt1.setMaximumSize(new Dimension(400, 70));
		opt1.setPreferredSize(new Dimension(400, 70));
		//always keep visible?
		opt1.setVisible(true);
		output.add(opt1);
		
		//add "Option 2" button to output panel
		opt2 = new JButton("Option 2");
		opt2.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				optChoice = 2;
				repaint();
			}
		});
		//set "Option 2" button size
		opt2.setMinimumSize(new Dimension(400, 70));
		opt2.setMaximumSize(new Dimension(400, 70));
		opt2.setPreferredSize(new Dimension(400, 70));
		//always keep visible?
		opt2.setVisible(true);
		output.add(opt2);
		
		//add "Option 3" button to output panel
		opt3 = new JButton("Option 3");
		opt3.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				optChoice = 3;
				repaint();
			}
		});
		//set "Option 3" button size
		opt3.setMinimumSize(new Dimension(400, 70));
		opt3.setMaximumSize(new Dimension(400, 70));
		opt3.setPreferredSize(new Dimension(400, 70));
		//always keep visible?
		opt3.setVisible(false);
		output.add(opt3);
		
		// add output panel to a JScrollPane to make it scrollable
		JScrollPane orderPane = new JScrollPane(output);
		//add border to panel
		orderPane.setBorder(BorderFactory.createTitledBorder("User Input"));
		return orderPane;
	}
	
	/**
	 * this method returns the directory specified by the user of images to be analyzed
	 */
	public String getVideoDirectory() {
		return video.imageDirectory;
	}
	
	/**
	 *  
	 */
	public int getUserResponse(String opt1Text, String opt2Text, String promptText, Image matImg) {
		optChoice = 0; 
		opt1.setText(opt1Text); opt2.setText(opt2Text);
		opt3.setVisible(false);
		prompt.setText("<html><br><u>User Instructions:</u><br><br>".concat(promptText).concat("<br><br>"));
		
		ImageIcon imgIcon = new ImageIcon(matImg);
		imageLabel.setIcon(imgIcon);
		repaint();
		
		// loop so matlab hangs, expecting a return value
		while(optChoice == 0) { System.out.print("");};
		return optChoice;
	}
	
	/**
	 *  	// overloaded function: if we want to display three choices
	 */	
	public int getUserResponse(String opt1Text, String opt2Text, String opt3Text, String promptText, Image matImg) {
		optChoice = 0;
		opt1.setText(opt1Text); opt2.setText(opt2Text); opt3.setText(opt3Text);
		opt3.setVisible(true);
		prompt.setText("<html><br><u>User Instructions:</u><br><br>".concat(promptText).concat("<br><br>"));
		
		ImageIcon imgIcon = new ImageIcon(matImg);
		imageLabel.setIcon(imgIcon);
		imageLabel.setPreferredSize(new Dimension(500,500));
		imageLabel2.setVisible(false);
		repaint();
		
		// loop so matlab hangs, expecting a return value
		while(optChoice == 0) { System.out.print("");};
		opt3.setVisible(false);
		return optChoice;
	}
	

	/**
	 *  	// overloaded function: if we want to display three choices and two images
	 */	
	public int getUserResponse(String opt1Text, String opt2Text, String opt3Text, String promptText, Image matImg1, Image matImg2) {
		optChoice = 0;
		opt1.setText(opt1Text); opt2.setText(opt2Text); opt3.setText(opt3Text);
		opt3.setVisible(true);
		prompt.setText("<html><br><u>User Instructions:</u><br><br>".concat(promptText).concat("<br><br>"));
		
		imageLabel.setIcon(new ImageIcon(matImg1));
		imageLabel2.setIcon(new ImageIcon(matImg2));
		imageLabel.setPreferredSize(new Dimension(500,350));
		imageLabel2.setPreferredSize(new Dimension(500,350));
		imageLabel2.setVisible(true);
		
		repaint();
		
		// loop so matlab hangs, expecting a return value
		while(optChoice == 0) { System.out.print("");};
		opt3.setVisible(false);
		return optChoice;
	}
	
	/**
	 *
	 */	
	public Image getImageFromArray(int[] pixels, int width, int height) {
	    MemoryImageSource mis = new MemoryImageSource(width, height, pixels, 0, width);
	    Toolkit tk = Toolkit.getDefaultToolkit();
	    System.out.println("image converted from array...\n");
	    System.out.println("Width?: " + Integer.toString(tk.createImage(mis).getWidth(null)) + "  Height?: " + Integer.toString(tk.createImage(mis).getHeight(null)));
	    
	    return tk.createImage(mis);
	}
	
	/**
	 *
	 */	
	public Video getVideo() {
		return video;
	}
	
	/**
	 *
	 */	
	public int askWhichFrameForTuner(int maxFrame) {
		int chosenFrame = 0;
		int correctInt = 0;
		while (correctInt == 0) {
			try {
				String intString = JOptionPane.showInputDialog(this, "Please enter a frame on which to tune detection! (in range: 1 to " + Integer.toString(maxFrame) + " )");
				chosenFrame = Integer.parseInt(intString);
				correctInt = 1;
			}
			catch(NumberFormatException nfe) {
				JOptionPane.showMessageDialog(this, "You must type a valid frame number!");
				correctInt = 0;
			}
			if (chosenFrame > maxFrame || chosenFrame < 1) {
				JOptionPane.showMessageDialog(this, "You must type a frame number between 1 and " + Integer.toString(maxFrame) + "!");
				correctInt = 0;
			}
		}
		return chosenFrame;
	}
	
	/**
	 *
	 */	
	public void showMessage(String message) {
		JOptionPane.showMessageDialog(this, message);
	}

	/**
	 *
	 */	
	public int showConfirmMessage(String message) {
		return JOptionPane.showConfirmDialog(this,message,"Please Choose",JOptionPane.YES_NO_OPTION);
	}
	
	/**
	 *
	 */
	public int showImage(Image matImg) {
		optChoice=0;
		imageLabel.setIcon(new ImageIcon(matImg));
		imageLabel.setPreferredSize(new Dimension(500,500));
		imageLabel2.setVisible(false);
		repaint();
		//while(optChoice == 0) { System.out.print("");};
		return optChoice;
	}
	
	/**
	 *  // overloaded method, this one displays 2 images
	 */	
	public int showImage(Image matImg1, Image matImg2) {
		optChoice=0;
		
		//set imageLabel
		imageLabel.setIcon(new ImageIcon(matImg1));
		imageLabel.setPreferredSize(new Dimension(500,350));
		
		//set imageLabel2
		imageLabel2.setIcon(new ImageIcon(matImg2));
		imageLabel2.setPreferredSize(new Dimension(500,350));
		imageLabel2.setVisible(true);
		
		repaint();
		
		while(optChoice == 0) { System.out.print("");};
		return optChoice;
	}
	
	/**
	 *  // display algorithm message on screen
	 */
	public void displayAlgorithmMessage(String message, boolean newItem) {
		if (newItem) {
			//add algoMessage to output panel
			algoMessage = new JLabel("<html><br>" + message + "<br>");
		} else {
			// update text
			algoMessage.setText("<html><br>" + message + "<br>");
		}
		Font curFont = algoMessage.getFont();
	    algoMessage.setFont(new Font(curFont.getFontName(), curFont.getStyle(), 14));
	    
		algoMessage.setVisible(true);
		output.add(algoMessage);
		repaint();
		output.revalidate();
	}
	
	/**
	 *
	 */	
	public void welcomeToTcmat() {
		JOptionPane.showMessageDialog(this,"Welcome to TIAM! Press OK to choose a video for analysis.","Welcome",1);
	}
	
	/**
	 *
	 */	
	public void makeVideo(String tcmatPath) {
		this.video = initVideo(tcmatPath);
	}
	
	/**
	 *
	 */	
	public int repeatOrQuit() {
		return JOptionPane.showConfirmDialog(this,"Analysis complete. Would you like to set up another video for analysis or quit? \n(Yes to set up another video, No to quit).","Repeat or Quit",JOptionPane.YES_NO_OPTION);
	}
	
	/**
	 * 
	 */
	public String getUserInput(String message){
		return JOptionPane.showInputDialog(this,message);
	}
	
	/**
	 *
	 */	
	public int showConfirmCancelMessage(String message) {
		return JOptionPane.showConfirmDialog(this,message,"Please Choose",JOptionPane.YES_NO_CANCEL_OPTION);
	}
}