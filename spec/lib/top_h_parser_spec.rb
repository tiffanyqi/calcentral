require 'spec_helper'

describe TopHParser do
  let(:top_h_file) do
    <<-EOF
top - 06:22:24 up 90 days, 20:52,  2 users,  load average: 1.15, 1.16, 1.08
Tasks: 534 total,   2 running, 532 sleeping,   0 stopped,   0 zombie
Cpu(s): 26.1%us,  0.5%sy,  0.0%ni, 73.2%id,  0.0%wa,  0.0%hi,  0.1%si,  0.0%st
Mem:  12197716k total, 11357656k used,   840060k free,   644256k buffers
Swap:  2097148k total,    28856k used,  2068292k free,  3769708k cached

  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND
32346 app_calc  20   0 7163m 3.8g  20m R 45.5 32.5 230:50.43 java
32345 app_calc  20   0 7163m 3.8g  20m S 31.5 32.5 442:35.68 java
32344 app_calc  20   0 7163m 3.8g  20m S 24.5 32.5 439:54.42 java
15336 app_calc  20   0 7163m 3.8g  20m S 12.3 32.5   1:52.72 java
11330 app_calc  20   0 13524 1496  840 R  3.5  0.0   0:00.06 top
15339 app_calc  20   0 7163m 3.8g  20m S  3.5 32.5   4:13.95 java
 1477 nscd      20   0 1251m 1880 1180 S  1.8  0.0   0:28.57 nscd
 3331 apache    20   0  193m 5948 2620 S  1.8  0.0   0:01.01 httpd
32455 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   0:23.51 java
15335 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   0:00.36 java
15340 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   3:39.64 java
 6951 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   1:36.62 java
10961 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   0:08.84 java
11006 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   0:06.33 java
11286 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   0:00.26 java
11287 app_calc  20   0 7163m 3.8g  20m S  1.8 32.5   0:00.18 java
    1 root      20   0 21324 1088  932 S  0.0  0.0   6:03.75 init
    2 root      20   0     0    0    0 S  0.0  0.0   0:00.51 kthreadd
31932 memcache  20   0  694m 375m  580 S  0.0  3.1   0:00.02 memcached
32252 app_calc  20   0  103m 1260 1228 S  0.0  0.0   0:19.21 standalone.sh
32332 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   0:00.00 java
32333 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   0:00.63 java
32334 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   2:44.63 java
32335 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   2:43.91 java
32336 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   2:43.99 java
11289 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   0:00.00 java


top - 06:22:27 up 90 days, 20:52,  2 users,  load average: 1.14, 1.16, 1.08
Tasks: 534 total,   2 running, 532 sleeping,   0 stopped,   0 zombie
Cpu(s): 42.3%us,  1.6%sy,  0.0%ni, 55.9%id,  0.0%wa,  0.0%hi,  0.2%si,  0.0%st
Mem:  12197716k total, 11358632k used,   839084k free,   644268k buffers
Swap:  2097148k total,    28856k used,  2068292k free,  3769908k cached

  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND
32346 app_calc  20   0 7163m 3.8g  20m S 54.4 32.5 230:52.07 java
32344 app_calc  20   0 7163m 3.8g  20m S 41.5 32.5 439:55.67 java
32345 app_calc  20   0 7163m 3.8g  20m R 35.2 32.5 442:36.74 java
 6951 app_calc  20   0 7163m 3.8g  20m S  7.6 32.5   1:36.85 java
10961 app_calc  20   0 7163m 3.8g  20m S  7.6 32.5   0:09.07 java
11006 app_calc  20   0 7163m 3.8g  20m S  6.6 32.5   0:06.53 java
11287 app_calc  20   0 7163m 3.8g  20m S  3.3 32.5   0:00.28 java
15336 app_calc  20   0 7163m 3.8g  20m S  2.7 32.5   1:52.80 java
15340 app_calc  20   0 7163m 3.8g  20m S  2.3 32.5   3:39.71 java
15339 app_calc  20   0 7163m 3.8g  20m S  2.0 32.5   4:14.01 java
11286 app_calc  20   0 7163m 3.8g  20m S  2.0 32.5   0:00.32 java
  737 app_calc  20   0 7163m 3.8g  20m S  1.7 32.5   1:26.95 java
15335 app_calc  20   0 7163m 3.8g  20m S  1.0 32.5   0:00.39 java
11330 app_calc  20   0 13532 1604  932 R  0.7  0.0   0:00.08 top
31930 memcache  20   0  694m 375m  580 S  0.7  3.1   1:43.70 memcached
32334 app_calc  20   0 7163m 3.8g  20m S  0.7 32.5   2:44.65 java
32335 app_calc  20   0 7163m 3.8g  20m S  0.7 32.5   2:43.93 java
32336 app_calc  20   0 7163m 3.8g  20m S  0.7 32.5   2:44.01 java
32337 app_calc  20   0 7163m 3.8g  20m S  0.7 32.5   2:44.80 java
32438 app_calc  20   0 7163m 3.8g  20m S  0.7 32.5   0:23.20 java
    3 root      RT   0     0    0    0 S  0.3  0.0   3:27.60 migration/0
11260 apache    20   0  193m 5100 2012 S  0.3  0.0   0:00.01 httpd
31929 memcache  20   0  694m 375m  580 S  0.3  3.1   0:47.32 memcached
32339 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   2:17.72 java
32604 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   0:01.61 java
 9007 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   0:00.43 java
    1 root      20   0 21324 1088  932 S  0.0  0.0   6:03.75 init
15328 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   0:00.15 java
15329 app_calc  20   0 7163m 3.8g  20m S  0.0 32.5   3:01.10 java


top - 06:22:30 up 90 days, 20:52,  2 users,  load average: 1.14, 1.16, 1.08
Tasks: 532 total,   4 running, 527 sleeping,   0 stopped,   1 zombie
Cpu(s): 35.0%us,  0.5%sy,  0.0%ni, 64.3%id,  0.0%wa,  0.0%hi,  0.2%si,  0.0%st
Mem:  12197716k total, 11355032k used,   842684k free,   644276k buffers
Swap:  2097148k total,    28856k used,  2068292k free,  3769972k cached

  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND
32346 app_calc  20   0 7163m 3.8g  20m R 47.8 32.5 230:53.52 java
32344 app_calc  20   0 7163m 3.8g  20m R 35.3 32.5 439:56.74 java
32345 app_calc  20   0 7163m 3.8g  20m R 34.6 32.5 442:37.79 java
11006 app_calc  20   0 7163m 3.8g  20m S  5.3 32.5   0:06.69 java
 6951 app_calc  20   0 7163m 3.8g  20m S  4.0 32.5   1:36.97 java
10961 app_calc  20   0 7163m 3.8g  20m S  3.0 32.5   0:09.16 java
15340 app_calc  20   0 7163m 3.8g  20m S  2.0 32.5   3:39.77 java
15336 app_calc  20   0 7163m 3.8g  20m S  1.6 32.5   1:52.85 java
11287 app_calc  20   0 7163m 3.8g  20m S  1.6 32.5   0:00.33 java
15339 app_calc  20   0 7163m 3.8g  20m S  1.3 32.5   4:14.05 java
11286 app_calc  20   0 7163m 3.8g  20m S  1.0 32.5   0:00.35 java
11330 app_calc  20   0 13532 1612  932 R  0.7  0.0   0:00.10 top
   22 root      20   0     0    0    0 S  0.3  0.0   5:50.48 events/3
11274 apache    20   0  193m 5328 2140 S  0.3  0.0   0:00.02 httpd
32334 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   2:44.66 java
32335 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   2:43.94 java
32336 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   2:44.02 java
32337 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   2:44.81 java
32384 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   0:10.81 java
32632 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   0:11.65 java
    1 root      20   0 21324 1088  932 S  0.0  0.0   6:03.75 init
    2 root      20   0     0    0    0 S  0.0  0.0   0:00.51 kthreadd
11260 apache    20   0  193m 5100 2012 S  0.3  0.0   0:00.01 httpd
31929 memcache  20   0  694m 375m  580 S  0.3  3.1   0:47.32 memcached
32339 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   2:17.72 java
32604 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   0:01.61 java
 9007 app_calc  20   0 7163m 3.8g  20m S  0.3 32.5   0:00.43 java

    EOF
  end

  describe '#parse_lines' do
    it 'converts a Java thread line to a hex PID' do
      result = subject.parse_lines [
        "32346 app_calc  20   0 7163m 3.8g  20m R 45.5 32.5 230:50.43 java                                    \n"
      ]
      expect(result).to eq([
        xpid: 'x7e5a',
        pid: '32346',
        cpu: 45.5,
        time: '230:50.43',
        run: 0
      ])
    end
    it 'ignores non-Java threads' do
      result = subject.parse_lines [
        "   18 root      RT   0     0    0    0 S  0.0  0.0   0:06.54 watchdog/3                              \n"
      ]
      expect(result).to be_blank
    end
    it 'ignores headers' do
      result = subject.parse_lines [
        "Mem:  12197716k total, 11357656k used,   840060k free,   644256k buffers\n"
      ]
      expect(result).to be_blank
    end
    it 'associates data with run position' do
      result = subject.parse_lines top_h_file.split "\n"
      popular_thread = result.select {|r| r[:pid] == '32345'}.collect {|r| r[:run]}
      expect(popular_thread).to eq [1, 2, 3]
      wallflower = result.select {|r| r[:pid] == '32332'}.collect {|r| r[:run]}
      expect(wallflower).to eq [1]
    end
  end

end
