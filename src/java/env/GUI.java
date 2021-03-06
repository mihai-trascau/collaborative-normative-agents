package env;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Vector;

import javax.imageio.ImageIO;
import javax.swing.*;

import cartagoEnvironment.*;

@SuppressWarnings("serial")
public class GUI extends JFrame implements Runnable {
	
	private Map map;
	private JLabel labelMap[][];
	private JPanel mapPanel;
	
	private HashMap<String, Color> agentColor;
	private Vector<Color> colorPool;
	
	
	public GUI(Map map) {
		super("Factory transport robots");
		
		this.setSize(1200, 770);
		//Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
		//this.setBounds(0,0,screenSize.width, screenSize.height);
		//this.setUndecorated(true);
		this.setDefaultCloseOperation(EXIT_ON_CLOSE);
		
		this.agentColor = new HashMap<String, Color>();
		this.colorPool = new Vector<Color>();
		colorPool.add(Color.RED);
		colorPool.add(Color.BLUE);
		colorPool.add(Color.CYAN);
		colorPool.add(Color.GREEN);
		colorPool.add(Color.MAGENTA);
		colorPool.add(Color.ORANGE);
		colorPool.add(Color.PINK);
		colorPool.add(Color.YELLOW);
		this.map = map;
		
		this.mapPanel = new JPanel(new GridLayout(map.getHeigth(), map.getWidth()));
		this.labelMap = new JLabel[map.getHeigth()][map.getWidth()];
		
		this.drawMap(null,null);
		
		
		for(int i = 0; i < map.getHeigth(); i++)
			for(int j = 0; j < map.getWidth(); j++)
				this.mapPanel.add(labelMap[i][j]);
		
		mapPanel.validate();
		mapPanel.repaint();
		
		this.getContentPane().add(mapPanel);
		new Thread(this).start();
		this.setVisible(true);
	}
	
	public synchronized void drawMap(Hashtable<String,Position> agentPosition, Hashtable<String, AgentState> agentState) {
		//mapPanel.removeAll();
		
		for(int i = 0; i < map.getHeigth(); i++)
			for(int j = 0; j < map.getWidth(); j++)
			{
				if(map.getPosition(i, j) == 0) {
					if(agentPosition == null)
						labelMap[i][j] = new JLabel(i+","+j);
					else {
						labelMap[i][j].setIcon(null);
						labelMap[i][j].setText(i+","+j);
					}
					labelMap[i][j].setOpaque(true);
					labelMap[i][j].setBackground(Color.WHITE);
					if (j == map.width-1)
						labelMap[i][j].setBackground(Color.ORANGE);
					labelMap[i][j].setForeground(Color.LIGHT_GRAY);
					labelMap[i][j].setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));
				}
				else if(map.getPosition(i, j) == 1) {
					if(agentPosition == null)
						labelMap[i][j] = new JLabel();
					else
						labelMap[i][j].setIcon(null);
					labelMap[i][j].setOpaque(true);
					labelMap[i][j].setBackground(Color.GRAY);
					labelMap[i][j].setForeground(Color.LIGHT_GRAY);
				}
				else if(map.getPosition(i, j) == 2) {
					if(agentPosition == null)
						labelMap[i][j] = new JLabel();
					else {
						labelMap[i][j].setText("");
						labelMap[i][j].setIcon(null);
					}
					labelMap[i][j].setOpaque(true);
					labelMap[i][j].setBackground(Color.ORANGE);
					labelMap[i][j].setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));
				}
				else if(map.getPosition(i, j) >= 20 && map.getPosition(i, j) < 30) {
					if(agentPosition == null)
						labelMap[i][j] = new JLabel();
					labelMap[i][j].setOpaque(true);
					labelMap[i][j].setBackground(Color.GRAY);
					int type = map.getPosition(i, j) % 20;
					labelMap[i][j].setIcon(getScaledIcon("res/img/crate_"+type+".png", 0.17));
				}
				else if(map.getPosition(i, j) >= 30 && map.getPosition(i, j) < 40) {
					if(agentPosition == null)
						labelMap[i][j] = new JLabel();
					labelMap[i][j].setOpaque(true);
					labelMap[i][j].setBackground(Color.DARK_GRAY);
				}
				else if(map.getPosition(i, j) >= 40) {
					if(agentPosition == null)
						labelMap[i][j] = new JLabel();
					labelMap[i][j].setOpaque(true);
					labelMap[i][j].setBackground(Color.DARK_GRAY);
					int type = map.getPosition(i, j) % 40;
					labelMap[i][j].setIcon(getScaledIcon("res/img/crate_"+type+".png", 0.17));
				}
				
				labelMap[i][j].setHorizontalAlignment(JLabel.CENTER);
				labelMap[i][j].setVerticalTextPosition(JLabel.BOTTOM);
				labelMap[i][j].setHorizontalTextPosition(JLabel.CENTER);
			}
		
		if(agentPosition != null) {
			for(String agentName : agentPosition.keySet()){
				int i = agentPosition.get(agentName).getX();
				int j = agentPosition.get(agentName).getY();
				
				if(!agentColor.containsKey(agentName))
					agentColor.put(agentName, colorPool.size() > 0 ? colorPool.remove(0) : Color.BLACK);
				labelMap[i][j].setForeground(agentColor.get(agentName));
				labelMap[i][j].setText(agentName);
				AgentState state = agentState.get(agentName);
				switch(state)
				{
				case CARRYING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/loaded_robot.png", 0.15));
					break;
				case IDLE_LOADING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/idle_robot.png", 0.15));
					break;
				case IDLE_UNLOADING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/idle_robot.png", 0.15));
					break;
				case LOADING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/loading_robot.png", 0.15));
					break;
				case UNLOADING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/unloading_robot.png", 0.15));
					break;
				case MOVING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/empty_robot.png", 0.15));
					break;
				case PLANNING:
					labelMap[i][j].setIcon(getScaledIcon("res/img/planning_robot.png", 0.15));
				}
			}
		}
		
		mapPanel.validate();
		mapPanel.repaint();
	}
	
	private ImageIcon getScaledIcon(String path, double scaleFactor) {
		try {
			BufferedImage crate = ImageIO.read(new File(path));
			return this.scale(crate, (int)(crate.getWidth()*scaleFactor), (int)(crate.getHeight()*scaleFactor));
		} catch (IOException e) {
			e.printStackTrace();
			return null;
		}
	}
	
	private ImageIcon scale(BufferedImage image, int width, int height) {
		int type = image.getType() == 0? BufferedImage.TYPE_INT_ARGB : image.getType();
		BufferedImage resizedImage = new BufferedImage(width, height, type);
		Graphics2D g = resizedImage.createGraphics();
		g.setComposite(AlphaComposite.Src);
		
		g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
		RenderingHints.VALUE_INTERPOLATION_BILINEAR);

		g.setRenderingHint(RenderingHints.KEY_RENDERING,
		RenderingHints.VALUE_RENDER_QUALITY);

		g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
		RenderingHints.VALUE_ANTIALIAS_ON);

		g.drawImage(image, 0, 0, width, height, null);
		g.dispose();
		return new ImageIcon(resizedImage);
		}

	public void run() {}
	
	public synchronized void drawPolicy(Hashtable<String,Position> agentPosition, int policy[][]) {
		//mapPanel.removeAll();
		JFrame policyFrame = new JFrame("Policy");
		policyFrame.setLayout(new GridLayout(map.getHeigth(), map.getWidth()));
		JLabel policyLabelMap[][] = new JLabel[map.getHeigth()][map.getWidth()];
		
		for(int i = 0; i < map.getHeigth(); i++)
			for(int j = 0; j < map.getWidth(); j++)
			{
				if(map.getPosition(i, j) == 0) {
					if(agentPosition == null)
						policyLabelMap[i][j] = new JLabel(i+","+j);
					else {
						//labelMap[i][j].setIcon(null);
						//labelMap[i][j].setText(i+","+j);
					}
					Position pos = new Position(i,j);
					if(policy[i][j] != -1)
						policyLabelMap[i][j].setIcon(getScaledIcon("res/arrows/arrow"+policy[i][j]+".jpg", 0.5));
					policyLabelMap[i][j].setOpaque(true);
					policyLabelMap[i][j].setBackground(Color.WHITE);
					if (j == map.width-1)
						policyLabelMap[i][j].setBackground(Color.ORANGE);
					policyLabelMap[i][j].setForeground(Color.LIGHT_GRAY);
					policyLabelMap[i][j].setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));
				}
				else if(map.getPosition(i, j) == 1) {
					if(agentPosition == null)
						policyLabelMap[i][j] = new JLabel();
					else
						policyLabelMap[i][j].setIcon(null);
					policyLabelMap[i][j].setOpaque(true);
					policyLabelMap[i][j].setBackground(Color.GRAY);
					policyLabelMap[i][j].setForeground(Color.LIGHT_GRAY);
				}
				else if(map.getPosition(i, j) == 2) {
					if(agentPosition == null)
						policyLabelMap[i][j] = new JLabel();
					else {
						policyLabelMap[i][j].setText("");
						policyLabelMap[i][j].setIcon(null);
					}
					policyLabelMap[i][j].setOpaque(true);
					policyLabelMap[i][j].setBackground(Color.ORANGE);
					policyLabelMap[i][j].setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));
				}
				else if(map.getPosition(i, j) >= 20 && map.getPosition(i, j) < 30) {
					if(agentPosition == null)
						policyLabelMap[i][j] = new JLabel();
					policyLabelMap[i][j].setOpaque(true);
					policyLabelMap[i][j].setBackground(Color.GRAY);
					int type = map.getPosition(i, j) % 20;
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/crate_"+type+".png", 0.17));
				}
				else if(map.getPosition(i, j) >= 30 && map.getPosition(i, j) < 40) {
					if(agentPosition == null)
						policyLabelMap[i][j] = new JLabel();
					policyLabelMap[i][j].setOpaque(true);
					policyLabelMap[i][j].setBackground(Color.DARK_GRAY);
				}
				else if(map.getPosition(i, j) >= 40) {
					if(agentPosition == null)
						policyLabelMap[i][j] = new JLabel();
					policyLabelMap[i][j].setOpaque(true);
					policyLabelMap[i][j].setBackground(Color.DARK_GRAY);
					int type = map.getPosition(i, j) % 40;
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/crate_"+type+".png", 0.17));
				}
				
				policyLabelMap[i][j].setHorizontalAlignment(JLabel.CENTER);
				policyLabelMap[i][j].setVerticalTextPosition(JLabel.BOTTOM);
				policyLabelMap[i][j].setHorizontalTextPosition(JLabel.CENTER);
			}
		
		if(agentPosition != null) {
			for(String agentName : agentPosition.keySet()){
				int i = agentPosition.get(agentName).getX();
				int j = agentPosition.get(agentName).getY();
				
				if(!agentColor.containsKey(agentName))
					agentColor.put(agentName, colorPool.size() > 0 ? colorPool.remove(0) : Color.BLACK);
				policyLabelMap[i][j].setForeground(agentColor.get(agentName));
				policyLabelMap[i][j].setText(agentName);
				AgentState state = AgentState.CARRYING;
				switch(state)
				{
				case CARRYING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/loaded_robot.png", 0.15));
					break;
				case IDLE_LOADING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/idle_robot.png", 0.15));
					break;
				case IDLE_UNLOADING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/idle_robot.png", 0.15));
					break;
				case LOADING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/loading_robot.png", 0.15));
					break;
				case UNLOADING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/unloading_robot.png", 0.15));
					break;
				case MOVING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/empty_robot.png", 0.15));
					break;
				case PLANNING:
					policyLabelMap[i][j].setIcon(getScaledIcon("res/img/planning_robot.png", 0.15));
				}
			}
		}
		
		for(int i = 0; i < map.getHeigth(); i++)
			for(int j = 0; j < map.getWidth(); j++)
				policyFrame.getContentPane().add(policyLabelMap[i][j]);

		policyFrame.pack();
		policyFrame.setVisible(true);
		//mapPanel.validate();
		//mapPanel.repaint();
	}
}