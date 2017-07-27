package
{
	import flash.display.Sprite;
	import flash.events.ActivityEvent;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.external.ExternalInterface;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	[SWF(frameRate="30",width="300",height="300")]
	/**
	 * RecordVideo<br>
	 * 
	 * @author zbself
	 * @E-mail zbself@qq.com
	 * @created 上午00:00:00 / 2017-1-1
	 * @see 
	 */
	public class RecordVideo extends Sprite
	{
		private var cam:Camera;//摄像头
		private var video:Video;//视频容器
		private var videoWidth:Number = 300;//视频宽
		private var videoHeight:Number = 300;//视频高
		private var audio:Microphone;//麦克风
		
		private var netConnection:NetConnection;//视频宽 fms连接
		private var appName:String = "bhh";
		private var rtmpURL:String = 'rtmpt://114.115.215.27:8080';//fms地址
		private var videoName:String = 'recordVideo';
		private var tfShow:String = "1";
		
		private var netStream:NetStream;
		
		private var tf:TextField;
		
		public function RecordVideo()
		{
			getURL();
			setJS();
//			Security.showSettings(SecurityPanel.PRIVACY );
			getCam();
			
		}
		/**
		 * 通过页面flashvars参数 获取新地址
		 * 如果没有，则使用默认地址 rtmpt://114.115.215.27:8080/bhh;
		 */		
		private function getURL():void
		{
			if( root.loaderInfo.parameters.hasOwnProperty( "tf" ))
			{
				tfShow = String(root.loaderInfo.parameters.tf);
			}
			
			if( root.loaderInfo.parameters.hasOwnProperty( "host" ))
			{
				var theHost:String = String(root.loaderInfo.parameters.host);
				if(theHost)
				{
					rtmpURL = "";
					rtmpURL = "rtmpt://"+theHost+":8080";
				}
			}
			if( root.loaderInfo.parameters.hasOwnProperty( "app" ))
			{
				var theApp:String = String(root.loaderInfo.parameters.app);
				if(theApp)
				{
					appName = "";
					appName = theApp;
				}
			}
			rtmpURL = rtmpURL + "/" +appName;
			
			htmlAlert( rtmpURL );
		}
		/**
		 * 设置javascript交互
		 */
		private function setJS():void
		{
			if(ExternalInterface.available)//浏览器环境
			{
				ExternalInterface.addCallback( "_start" , startRecord );//允许js访问
				ExternalInterface.addCallback( "_stop" , stopRecord );//允许js访问
				ExternalInterface.addCallback( "_recordName" , nameRecord );//允许js访问
			}
		}
		/**
		 * JS 启动
		 */
		private function startRecord():void
		{
			showTips( 'start recording...' );
			
			if(netConnection)
			{
				netConnection.connect( rtmpURL );//启动连接FMS connect
			}
		}
		/**
		 * JS 停止
		 */
		private function stopRecord():void
		{
			showTips( 'stop recording' );
			if( netStream )
			{
				netStream.close();
			}
			if( netConnection.connected )
			{
				netConnection.close();
			}
		}
		/**
		 * JS 修改录像名称
		 */
		private function nameRecord( value:*):void
		{
			showTips( 'record name : '+value );
			videoName = String( value );
		}
		/**
		 * 获取摄像头
		 */
		private function getCam():void
		{
			if( Camera.isSupported )//支持 摄像头
			{
				cam = Camera.getCamera();
				
				if( cam != null )
				{
					cam.setMode( videoWidth , videoHeight , 30 , false );
					cam.setQuality(163854,80);
					cam.addEventListener(StatusEvent.STATUS,camStatusHandler);
					cam.addEventListener(ActivityEvent.ACTIVITY,camActivityHandler);
					
					creatVideo();
					creatNetConnection();
					creatTFT();
					
//					startRecord();//测试自动连接
				}else{
					Security.showSettings(SecurityPanel.PRIVACY );
				}
			}
			
			if( Microphone.isSupported )//支持 麦克风
			{
				audio = Microphone.getMicrophone();
				
				if( audio )
				{
					//设置麦克风
					audio.setLoopBack(true);
					audio.setUseEchoSuppression(true);
					audio.addEventListener(StatusEvent.STATUS,audioStatusHandler);
					//压缩音频
					audio.codec = SoundCodec.SPEEX;
					audio.encodeQuality = 6;
					audio.noiseSuppressionLevel = 0;
				}
			}
		}
		/**
		 * 创建视频
		 */
		private function creatVideo():void
		{
			video = new Video( videoWidth , videoHeight );//初始化视频对象
			video.attachCamera( cam );//本地摄像赋给视频
			this.addChild( video );//显示视频
		}
		/**
		 * 创建FMS连接
		 */
		private function creatNetConnection():void
		{
			trace('创建fms');
			netConnection = new NetConnection();//创建连接
			netConnection.client = this;//回调为本机
			netConnection.addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);//连接状态
			
		}
		private function creatNetStream():void
		{
			netStream = new NetStream( netConnection );
			netStream.client = this;
			if( audio )	netStream.attachAudio( audio );
			if( cam )	netStream.attachCamera( cam );
			netStream.publish( videoName,'record');//在线录像模式
		}
		private function creatTFT():void
		{
			tf = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			var tft:TextFormat = new TextFormat('宋体',12,0xff0000);
			tf.defaultTextFormat = tft;
			this.addChild( tf );
			tf.visible = Boolean(Number( tfShow ));//文本提示是否可见
		}
		private function showTips( char:String = ""):void
		{
			if( tf ) tf.text = char;
		}
		
		protected function camActivityHandler(event:ActivityEvent):void
		{
			
		}
		protected function camStatusHandler(event:StatusEvent):void
		{
			switch(event.code) {
				
				case "Camera.Unmuted":
					trace('用户 允许访问摄像头');
					break;
				case "Camera.Muted":
					trace('用户 不允许访问摄像头');
					break;
			}
		}		
		protected function audioStatusHandler(event:StatusEvent):void
		{
			trace("audio statusHandler: " + event);
		}
		
		protected function onNetStatus(event:NetStatusEvent):void
		{
			trace('~'+event.info.code);
			switch(event.info.code){
				case "NetConnection.Connect.Success":
					trace('连接尝试成功');
					creatNetStream();
				break;
				case "NetConnection.Connect.Closed":
					trace('成功关闭连接');
				break;
				case "NetConnection.Connect.Failed":
					htmlAlert("服务器连接失败");
					trace('连接尝试失败');
				break;
				case "NetConnection.Connect.Rejected":
					htmlAlert("连接无权限");
					trace('连接尝试没有访问应用程序的权限');
				break;
			}
		}
		private function htmlAlert(char:String):void
		{
			if( ExternalInterface.available)
			{
				ExternalInterface.call('alert',char);
			}
		}
	}
}