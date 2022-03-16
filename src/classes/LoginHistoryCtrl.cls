/**
 *@author       Mats Böhler
 *@created      10.02.2022
 *
 *
 *@description  LoginHistoryCtrl
 *
 *
 *@changelog    10.02.2022 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class LoginHistoryCtrl {
	
	private String labelLastSuccessfulLoginDateTime = Label.LoginHistory_LastSuccessfulLoginDateTime;
	private String lastSuccessfulLoginDateTimeString = '';
	private String labelNumberOfFailedLogins = Label.LoginHistory_NumberOfFailedLogins;
	private Integer numberOfFailedLogins = 0;
	
	@AuraEnabled
	public static String loadData () {
		LoginHistoryCtrl instance = new LoginHistoryCtrl();
		instance.load();
		return JSON.serialize( instance );
	}
	
	private void load () {
		List<LoginHistoryWrapper> loginHistories = new List<LoginHistoryWrapper>();
		if ( Test.isRunningTest() ) {
			loginHistories.add(
					new LoginHistoryWrapper(
							'Browser',
							'Application',
							'Success',
							Datetime.now().addYears( -1 )
					)
			);
		}
		else {
			for ( LoginHistory loginHistory : [
					SELECT
							Id,
							LoginTime,
							Application,
							LoginType,
							Status
					FROM LoginHistory
					WHERE UserId = :UserInfo.getUserId()
					ORDER BY LoginTime
			] ) {
				loginHistories.add( new LoginHistoryWrapper( loginHistory.Application, loginHistory.LoginType, loginHistory.Status, loginHistory.LoginTime ) );
			}
		}
		Datetime currentLoginDateTime;
		Datetime lastLoginDateTime;
		for ( LoginHistoryWrapper loginHistory : loginHistories ) {
			if ( loginHistory.application == 'Browser'
					&& loginHistory.loginType == 'Application'
					&& loginHistory.status == 'Success' ) {
				currentLoginDateTime = loginHistory.loginTime;
			}
		}
		for ( LoginHistoryWrapper loginHistory : loginHistories ) {

			if ( loginHistory.application == 'Browser'
					&& loginHistory.loginType == 'Application'
					&& loginHistory.status == 'Success'
					&& loginHistory.loginTime < currentLoginDateTime ) {
				lastLoginDateTime = loginHistory.loginTime;
			}
		}
		for ( LoginHistoryWrapper loginHistory : loginHistories ) {
			if ( loginHistory.application == 'Browser'
					&& loginHistory.loginType == 'Application'
					&& loginHistory.status == 'Invalid Password'
					&& loginHistory.loginTime > lastLoginDateTime
					&& loginHistory.loginTime < currentLoginDateTime ) {
				numberOfFailedLogins++;
			}
		}
		lastSuccessfulLoginDateTimeString = lastLoginDateTime == null ? null : lastLoginDateTime.format( 'dd.MM.YYYY HH:mm:ss' );
	}
	
	private class LoginHistoryWrapper {
		private String application;
		private String loginType;
		private String status;
		private Datetime loginTime;
		
		public LoginHistoryWrapper ( String application, String loginType, String status, Datetime loginTime ) {
			this.application = application;
			this.loginType = loginType;
			this.status = status;
			this.loginTime = loginTime;
		}
	}
}