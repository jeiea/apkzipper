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
mcset ko {Log level:} {기록 수준:}
mcset ko {Debug} {디버그}
mcset ko {Info} {정보}
mcset ko {Warning} {경고}
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
mcset ko {Both}      		{소스와 리소스}
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
mcset ko {Explore app dir} {앱이있는 폴더 열기}
mcset ko {Explore dex dir} {오덱스 폴더 열기}
mcset ko {Optimize png} {PNG 최적화}
mcset ko {Deodex} {디오덱스}
mcset ko {Dex} {덱스}
mcset ko {View java source} {자바소스 보기}
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
mcset ko {Please extract/decompile app first.} {먼저 앱을 압축풀기/디컴파일 해주세요.}
mcset ko {jar compiling...} {jar 컴파일 중...}
mcset ko {apk compiling...} {apk 컴파일 중...}
mcset ko {Compile failed. Task terminated.} {컴파일하는데 실패했습니다.}
mcset ko {Adjusting compressing level...} {압축세기에 맞게 재압축 하는 중...}
mcset ko {Select framework files} {프레임워크 파일들을 선택해주세요}
mcset ko {Signing failed} {사인에 실패했습니다}
mcset ko Signed {사인되었습니다}
mcset ko {Zipaligned} {압축정렬 되었습니다}
mcset ko {Type remote path to push} {덮어쓸 안드로이드 경로를 입력해주세요}
mcset ko {Type remote path to pull} {가져올 안드로이드 경로를 입력해주세요}
mcset ko {Pushing... %s --> %s} {보내는 중... %s --> %s}
mcset ko {Pulling... %s --> %s} {가져오는 중... %s --> %s}
mcset ko { finished.} { 완료.}
mcset ko {ADB logcat executed} {폰 로그 기록이 시작되었습니다}
mcset ko {ADB logcat executed: %s} {폰 로그 기록이 시작되었습니다: %s}
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

mcset ko {%1$s and %2$d others} {%1$s외 %2$d개}
mcset ko {Downloading...} {다운로드 중...}
mcset ko {Installing: %s} {설치 중: %s}
mcset ko {Please connect to device first.} {먼저 폰을 연결해주세요.}


mcset ko {%d items are deleted.} {%d개 항목을 삭제했습니다.} 
mcset ko (folder) (폴더)
mcset ko {Notice} {알림}
mcset ko {The certificate doesn't match the device's.} {이미 폰에 설치되어 있는 앱과 사인이 다릅니다.}
mcset ko {Config file of not compatible version was found.} {호환되지 않는 버전의 설정파일을 찾았습니다.}
mcset ko {Due to major version difference, it'll use default setting.} {버전 차이가 너무 커서 기본값을 쓰게 됩니다.}
mcset ko {Keep in mind that settings will be overwritten when termination.} {프로그램 종료 시 설정파일이 덮어씌워지니 유의해주세요.}
mcset ko {If problem occurs, you can use reset function.} {문제가 발생하면 설정파일 초기화기능을 사용해주세요.}
mcset ko {File name malformed.} {파일 이름이 잘못되었습니다.}
mcset ko {Please retry after rename. (e.g. test.apk)} {파일 이름을 간단하게 바꾼 후 시도해주세요. (예:test.apk)}
mcset ko {Config file of different version was found.} {다른 버전의 설정파일을 찾았습니다.}

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
mcset ko {[::View::switchView} {[::View::switchView}
mcset ko {File is required: %s} {파일이 필요합니다: %s}
mcset ko {Access denied: %s} {접근 거부됨: %s}
mcset ko {Cannot find classes.dex} {classes.dex파일을 찾을 수 없습니다}
mcset ko {Deodexing...} {디오덱스 중...}
mcset ko {Odexing... } {오덱스 중... }
mcset ko { Complete.} { 완료.}
mcset ko {Error opening config file: %s} {설정파일을 여는 중 에러발생: %s}
mcset ko {Runtime error occured.} {런타임 에러가 발생했습니다.}
mcset ko {Dexing... } {classes.dex 묶는 중... }
mcset ko {Path} {Path}
mcset ko {Is directory?} {폴더여부}
mcset ko {Extracting...} {압축 푸는 중...}
mcset ko {Extraction finished.} {압축이 풀렸습니다.}
mcset ko {Decompiling...} {디컴파일 중...}
mcset ko {Successfully decompiled.} {디컴파일 되었습니다.}
mcset ko {Successfully compiled.} {컴파일 되었습니다.}
mcset ko {Restoring original resource and manifest...} {원본 리소스와 매니페스트 복원 중...}
mcset ko {Compressing...} {압축 중...}
mcset ko {Compressed.} {압축되었습니다.}
mcset ko {Framework installing...} {프레임워크 설치 중...}
mcset ko {Framework installed.} {프레임워크가 전부 설치되었습니다.}
mcset ko {Signing failed: %s} {사인 실패: %s}
mcset ko {Signed: %s} {사인됨: %s}
mcset ko {Zipaligned: %s} {압축 정렬 됨: %s}
mcset ko {Zipaligning...} {압축 정렬 중...}
mcset ko {Picture optimizing...} {그림 파일 최적화 중...}
mcset ko {Picture optimization finished.} {그림 파일 최적화 완료.}
mcset ko {Converting dex to jar...} {dex를 jar로 변환 중...}
mcset ko {Are you sure you want to delete these items?} {정말 이 항목들을 지우겠습니까?}
mcset ko {Maybe these are sent to recycle bin.} {가능하면 휴지통으로 보내집니다.}
mcset ko {It seems config file not exists. } {설정파일이 없습니다. }
mcset ko {Default applied.} {기본값을 적용합니다.}
mcset ko {Choose project directory} {불러올 작업폴더를 선택해주세요}
mcset ko {Change to manual mode} {수동 모드로 전환}
mcset ko {Pack} {앱파일 만들기}
mcset ko {detailView} {수동모드로 전환(&M)}
mcset ko {simpleView} {간단모드로 전환(&M)}
mcset ko {tutorialView} {튜토리얼모드로 전환(&M)}
mcset ko {Complete.} {완료.}
mcset ko {Import} {불러오기}
mcset ko {Modify and pack} {수정하고 싸매기}
mcset ko {Export} {마무리작업}
mcset ko {Select .apk, .jar file from a local disk.} {.apk/.jar파일을 불러옵니다.}
mcset ko {Import file from connected device.} {폰에서 파일을 가져옵니다.}
mcset ko {Extract selected files' contents.
It's enough to modify .png images.} {앱을 압축풀기합니다.
사진 파일만 바꿀 때는 이걸로 충분합니다.}
mcset ko {Unpack selected files' contents with decoding some source code to smali.
Right click is 'Install framework' which registers
required files for compile/decompile.} {선택한 앱의 .xml을 추출하고 일부 소스코드를 smali형식으로 변환합니다.

우클릭하면 컴파일/디컴파일에 필요한 파일을 등록하는
프레임워크 설치를 합니다.}
mcset ko {Decode the .odex file.
It should be on same location.} {.odex파일을 smali형식으로 분해합니다.
.odex파일이 선택한 앱과 같은 경로에 같은 이름으로 있어야 합니다.}
mcset ko {Reduce .png files' size.
There's not quality decrease.} {사진파일의 크기를 줄입니다.
화질저하는 없습니다.}
mcset ko {Register files required to compile/decompile.} {컴파일/디컴파일에 필요한 파일을 등록합니다.}
mcset ko {Open extracted contents' directory} {분해한 내용물이 있는 폴더를 엽니다}
mcset ko {Open .odex contents' directory} {.odex파일을 분해한 폴더를 엽니다}
mcset ko {Pack deodexed contents.
If you do it before zip/compile, changes will be applied.} {분해한 .odex를 조립합니다.
이걸하고 압축/컴파일하면 수정한 내용이 반영됩니다.}
mcset ko {Pack 'Extracted' contents.
Don't use it with 'Decompile'} {재압축합니다.
디컴파일하고서 쓰지 마세요.}
mcset ko {Pack decompiled contents.
Don't use it with 'Extract'
Right click is 'System compile' which preserve resource.arsc} {디컴파일로 분해한 것을 조립합니다.
압축풀기하고서 쓰지 마세요.

우클릭하면 resource.arsc를 보존하는 시스템컴파일을 합니다.
SystemUI.apk같은 시스템 앱들을 컴파일할 때 상단바 사라짐 등을 방지합니다.}
mcset ko {Sign packed .apk/.jar file.
Original sign will be remained after packing.} {조립한 .apk/.jar파일에 서명합니다.
압축/컴파일 한 후엔 원래의 서명이 남아있는 상태입니다.
하지만 수정사항 때문에 원본과 달라져 서명이 무효화되었을 수 있습니다.
이 경우 앱이 동작하다가 맛이 가거나 합니다.
시스템 앱에는 서명이 필요 없습니다.}
mcset ko {Refine packed .apk/jar file.
If you sign after zipalign, alignment may be ruined.} {조립한 파일을 다듬습니다.
사인을 할 거면 사인한 후에 이걸 하세요. 맨 마지막 수정작업이라고 생각하면 됩니다.
안 해도 에러가 뜨지는 않지만 최적화의 효과가 있습니다.}
mcset ko {Install .apk file to a device.
System app maybe cannot.} {조립한 앱을 폰에 설치합니다.
시스템 앱은 아마 불가능합니다.}
mcset ko {Send file to a device.} {조립한 앱을 폰에 전송합니다.}
mcset ko {Initializing ADB...} {ADB 시동 중...}
mcset ko {Save To Log} {에러메시지 저장}
mcset ko {OK} {확인}
mcset ko {Application Error} {프로그램 에러}
mcset ko {Error: %1$s} {에러: %1$s}
mcset ko {Skip Messages} {무시}
mcset ko {Details >>} {세부 사항 >>}
mcset ko {Log Files} {로그 파일}
mcset ko {Text Files} {텍스트 파일}
mcset ko {All Files} {모든 파일}
mcset ko {Select Log File} {로그파일 경로를 선택해주세요}
mcset ko {&Reset config/history} {설정/히스토리 초기화(&R)}
mcset ko {Configuration is set to default.} {설정이 초기화되었습니다.}
mcset ko {simpleView is incomplete feature. Avoid to use it.} {간단모드는 미완성 기능입니다. 안 쓰는 게 좋을 거예요.}
mcset ko {Unsigned file not found.} {사인할 파일이 없습니다.}
mcset ko {It seems to be signed already.} {이미 사인이 된 것 같습니다.}
mcset ko {Supported command:} {쓸 수 있는 명령어: 설명}
mcset ko {push [<remote path>]} {push [<폰 경로>]: 선택한 앱을 지정한 경로로 전송합니다.}
mcset ko {push <local> <remote>} {push <로컬 경로> <폰 경로>: 지정한 폴더 및 파일을 전송합니다.}
mcset ko {pull <remote path>} {pull <폰 경로>: 지정한 파일 및 폴더를 가져옵니다.}
mcset ko {pull <remote> <local>} {pull <폰 경로> <로컬 경로>: 지정한 위치에 가져옵니다.}
mcset ko {Numbers written in detail view are accepted.} {수동모드에 있는 버튼 숫자도 명령어로 쓸 수 있습니다.}
mcset ko {shell, connect, exit} {shell, connect, exit}
mcset ko {Successfully system compiled.} {시스템컴파일 되었습니다.}
mcset ko {Bug report} {버그 리포트}
mcset ko {Are you OK?} {괜찮겠습니까?}
mcset ko {Report file has been sent.} {리포트 파일이 전송되었습니다.}
mcset ko {Cannot connect to server.} {서버 접속에 실패해 리포트하지 못했습니다.}
mcset ko {Auto decompile} {프레임워크 설치와 디컴파일}
mcset ko {Connected.} {연결되었습니다.}
mcset ko {Already connected.} {이미 연결되어있습니다.}
mcset ko {Failed to connect.} {연결하지 못했습니다.}
mcset ko {%s is already optimized.} {%s는 이미 최적화되어 있습니다.}
mcset ko {%1$s is %2$s compressed.} {%1$s가 %2$s더 압축되었습니다.}
mcset ko {Ziplevel:} {압축세기:}
mcset ko {Decompile target:} {디컴파일 대상:}
mcset ko {Config} {설정}
mcset ko {Cancel} {취소}
mcset ko {Reset to previous} {되돌리기}
mcset ko {Auto update} {자동 업데이트}
mcset ko {&Configuration} {설정(&C)}
mcset ko {Can't locate needed resource} {필요한 파일들을 찾을 수 없습니다}
mcset ko {How about copy /system/framework folder to path where .apk file exists?} {/system/framework폴더를 앱 파일이 있는 폴더에 복사해보고 
상단메뉴에서 간단모드로 들어가 '프레임워크 설치와 디컴파일'하면 될지도 모릅니다.}
mcset ko {This error is unfamiliar. Please report as bug.} {처음보는 에러입니다. 버그리포트 대상 ㅇㅅㅇ}
mcset ko {You can record process invoking problem.} {문제 발생 과정을 녹화할 수 있습니다. 그냥 넘어갈 수도 있지만...}
mcset ko {This archive file will be sent intactly.} {이 압축파일을 그대로 보냅니다.}
mcset ko {You can add some attachment at this step.} {지금 추가로 첨부할 파일을 넣어도 됩니다.}
mcset ko {Will you send it?} {이 버그리포트 파일을 보낼까요?}
mcset ko {Operation to other extension} {다른 확장자파일 추가여부}
mcset ko {Ask} {물어보기}
mcset ko {Cannot detect api level. Default value applied.} {API레벨 감지에 실패했습니다. 기본값이 적용됩니다.}
mcset ko {Operation to other extension:} {다른 확장자를 가진 파일 처리:}
mcset ko {Executable directory} {실행파일 폴더}
mcset ko {Apk directory} {앱 파일 폴더}
mcset ko {Project location:} {projects 폴더 위치:}
mcset ko {Can't locate needed file: %s} {필요한 파일이 없습니다: %s}
