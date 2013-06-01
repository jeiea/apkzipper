package require    msgcat
namespace import ::msgcat::*

mcset ko ApkZipper ApkZipper
mcset ko "ApkZipper %s %s" "ApkZipper %s %s"


# Commons
mcset ko Sorry 죄송합니다
mcset ko Input 입력
mcset ko Delete 삭제
mcset ko Confirm 확인
mcset ko Processing {처리 중...}
mcset ko {Error} 에러
mcset ko {ERROR} {에러}
mcset ko {Success.} 성공.
mcset ko {Failed.} 실패.
mcset ko {Yes} 예
mcset ko {No} 아니오
mcset ko {Yes to all} {모두 예}
mcset ko {No to all} {모두 아니오}

# File open dialog

# Main window menu
mcset ko {&Config}			{설정(&C)}
mcset ko {&SDK Function}	{SDK(&S)}
mcset ko {&Etc Function}	{기타(&E)}
mcset ko {Zip level} 		{압축세기}
mcset ko {Ziplevel 0}		{0 (압축 안 함)}
mcset ko {Ziplevel 1}		1
mcset ko {Ziplevel 2}		2
mcset ko {Ziplevel 3}		3
mcset ko {Ziplevel 4}		4
mcset ko {Ziplevel 5}		5
mcset ko {Ziplevel 6}		6
mcset ko {Ziplevel 7}		7
mcset ko {Ziplevel 8}		8
mcset ko {Ziplevel 9}		{9 (최고 압축)}
mcset ko {Decompile target}	{디컴파일 대상}
mcset ko {Sources}			{소스만}
mcset ko {Resources}		{리소스만}
mcset ko {Both}      		{둘 다}
mcset ko {The others}		{나머지만}
mcset ko {ADB Shell}		{ADB Shell}
mcset ko {Take phone log}	{폰 로그 가져오기}
mcset ko {ADB Connect}   	{ADB 원격접속}
mcset ko {Reboot}        	{리부팅}
mcset ko {Enter recovery}	{복구모드로 진입}
mcset ko {Enter download}	{다운로드모드로 진입}
mcset ko {Check update}		{업데이트 확인}
mcset ko {Visit website}	{홈페이지}
mcset ko {Help}				{도움말}

mcset ko {Clean folder}		{폴더 정리}
mcset ko {Delete current result} {현재 결과물 삭제}
mcset ko {Delete current workdir} {현재 작업폴더 삭제}
mcset ko {Delete current except original} {현재 원본만 빼고 삭제}
mcset ko {Delete current all} {현재 선택한 것 전부 삭제}
mcset ko {Delete all result} {모든 결과물 삭제}
mcset ko {Delete all workdir} {모든 작업폴더 삭제}
mcset ko {Delete all except original} {모두 원본만 빼고 삭제}
mcset ko {Delete all} {모두 삭제}

# Main window button
mcset ko {Import from phone} {폰에서 가져오기}
mcset ko {Select app} {앱 선택하기}
mcset ko {Select app recent} {최근 앱 선택}
mcset ko {Extract} {압축풀기}
mcset ko {Decompile} {디컴파일}
mcset ko {Install framework} {프레임워크 설치}
mcset ko {Explore project} {작업폴더 열기}
mcset ko {Optimize png} {PNG 최적화}
mcset ko {Recompress ogg} {OGG 재압축}
mcset ko {Zip} {압축}
mcset ko {Compile} {컴파일}
mcset ko {System compile} {시스템 컴파일}
mcset ko {Sign} {사인}
mcset ko {Zipalign} {압축정렬}
mcset ko {Install} {설치하기}
mcset ko {Export to phone} {폰으로 내보내기}

# Other dialogs
mcset ko {Extension mismatch} {확장자 불일치}
mcset ko "Do you want to import this?\n%s" "확장자가 .apk가 아닙니다.\n정말 다음 파일을 추가할까요?\n%s"
mcset ko {Not yet ready} {아직 준비되지 않았습니다}
mcset ko {Cannot access to %s} {%s에 접근할 수 없습니다}
mcset ko {Please wait} {기다려주세요}
mcset ko {Already op exist} {다른 작업이 진행 중 입니다}
mcset ko {Type android net address} {안드로이드의 IP주소를 입력해주세요}

mcset ko {You can select multiple files or folders} {Shift, Ctrl키로 여러 개의 파일 혹은 폴더를 선택할 수 있습니다}
mcset ko {All readable file} {앱 파일}
mcset ko {Apk file} {.apk 파일}
mcset ko {Jar file} {.jar 파일}
mcset ko {All file} {모든 파일}
mcset ko {Access denied: %1$s} {접근 거부됨: %1$s}

# GUI
mcset ko {Right click: %s} {우클릭: %s}



mcset ko {Abort} {취소}
mcset ko {Retry with conserving data} {데이터를 보존하면서 재설치}
mcset ko {Retry with removing data} {데이터를 삭제하면서 재설치}
mcset ko {Waiting for device... Aborting is Ctrl+C} {휴대폰 연결을 기다리는 중... 취소하려면 Ctrl+C를 눌러주세요}
mcset ko {Type path of android file} {안드로이드 파일경로를 입력하세요}
mcset ko {Please extract/decompile app first.} {먼저 앱을 압축해제/디컴파일 해주세요.}
mcset ko {jar compiling...} {jar 컴파일 중...}
mcset ko {apk compiling...} {apk 컴파일 중...}
mcset ko {Compile failed. Task terminated.} {컴파일하는데 실패했습니다.}
mcset ko {Adjusting compressing level...} {압축세기에 맞게 재압축 하는 중...}
mcset ko {Select framework file or folder} {프레임워크가 있는 폴더를 선택해주세요}
mcset ko {Signing failed} {사인에 실패했습니다}
mcset ko Signed {사인되었습니다}
mcset ko {Zipalign failed} {압축정렬에 실패했습니다}
mcset ko {Zipaligned} {압축정렬 되었습니다.}
mcset ko {Type android push path} {파일을 넣을 안드로이드 경로를 입력해주세요}
mcset ko {Pushing...} {전송 중...}
mcset ko { finished.} { 완료.}
mcset ko {ADB logcat executed} {폰 로그 기록이 시작되었습니다}
mcset ko {ADB logcat terminated} {폰 로그 기록이 종료되었습니다}
mcset ko {Connecting...} {접속 중...}
mcset ko {ADB connecting...} {접속 중... }
mcset ko {Checking update..} {업데이트 확인 중..}
mcset ko {There are no updates available.} {현재 최신버전을 사용 중 입니다.}
mcset ko {New version found!} {새 버전을 찾았습니다!}
mcset ko {Do you want to update?} {업데이트 하겠습니까?}
mcset ko {Update info not found. Please check website.} {업데이트 정보를 찾지 못했습니다. 홈페이지에서 최신버전을 확인해주세요.}
mcset ko "You choosed %s.\nis this right? this task is unrecovable." "%s를 골랐습니다.\n이 작업은 취소할 수 없습니다. 계속하겠습니까?"
mcset ko "Java not found.\nTo solve this problem, install JRE or JDK." "자바를 찾지 못했습니다.\n자바 런타임을 설치해주세요."

mcset ko {%1$s and %2$d others} {%1$s 외 %2$d개}
mcset ko {Downloading...} {다운로드 중...}
mcset ko {Please connect to device first.} {먼저 폰을 연결해주세요.}


mcset ko "File name malformed.\nPlease retry after rename. (e.g. test.apk)" "파일 이름이 잘못되었습니다.\n파일이름을 간단하게 바꾼 후 시도해주세요."

# Dummy

mcset ko {Tuner} {값 조절부분}
mcset ko FLASH_RECOVERY {}
mcset ko {$label} {}
mcset ko {Ziplevel $idx} {}
mcset ko {$item} {}
mcset ko {$proc} {}
mcset ko {$proc2} {}
mcset ko {ADB $cmd} {}
mcset ko {$detail} {}
mcset ko "(\{\[^\}" {}
