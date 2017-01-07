/**
 * The Video class holds information about a video for the TcMatGui class
 */

public class Video {
	
	public String name;
	public String imageDirectory;
	public int numChannels;
	public int dicChannel;
	public int irmChannel;
	public int fluorChannel1;
	public int fluorChannel2;
	public int outlineChannel;
	// csmacChannel? (is this fluor1/fluor2?)
	
	
	/**
	 * Create a new video object.
	 */
	public Video(String name, String imageDirectory, int numChannels, int[] channelArray) {
		
		this.name = name;
		this.imageDirectory = imageDirectory;
		this.numChannels = numChannels;

		// use channelArray to initialize channels
			//note: channels (irmChannel, fluorChannel1, etc.) set equal to zero when not used.
		this.dicChannel = channelArray[0];
		this.irmChannel = channelArray[1];
		this.fluorChannel1 = channelArray[2];
		this.fluorChannel2 = channelArray[3];
		this.outlineChannel = channelArray[4];
	}
	
	public String getName() {
		return this.name;
	}
	
	public String getDir() {
		return this.imageDirectory;
	}
	
	public int getNumChannels() {
		return this.numChannels;
	}
	
	public int getDicChannel() {
		return this.dicChannel;
	}
	
	public int getIrmChannel() {
		return this.irmChannel;
	}
	
	public int getFluorChannel1() {
		return this.fluorChannel1;
	}
	
	public int getFluorChannel2() {
		return fluorChannel2;
	}

	public int getOutlineChannel() {
		return outlineChannel;
	}
	
	public int[] getChannelArray() {
		int[] channelArray = {this.dicChannel, this.irmChannel, this.fluorChannel1, this.fluorChannel2, this.outlineChannel};
		return channelArray;
	}
	
}