using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Analyzer
{

    class Program
    {

        struct Entry
        {
            public double TotalTime { get; set; }
            public bool IsOK { get; set; }
            public long Timestamp { get; internal set; }
            public string File { get; internal set; }
        }

        private static double Percentile(double[] sequence, double excelPercentile)
        {
            Array.Sort(sequence);
            int N = sequence.Length;
            double n = (N - 1) * excelPercentile + 1;
            // Another method: double n = (N + 1) * excelPercentile;
            if (n == 1d) return sequence[0];
            else if (n == N) return sequence[N - 1];
            else
            {
                int k = (int)n;
                double d = n - k;
                return sequence[k - 1] + d * (sequence[k] - sequence[k - 1]);
            }
        }

        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Specify directory where runs are stored");
                return;
            }

            bool filterOutStartAndEnd = !args.Any(a => a =="--filter-for-loss");

            List<IEnumerator<Entry>> allEntries = new List<IEnumerator<Entry>>();


            Console.WriteLine("name;n;ok;earliestTS;TSwhenAllPodsAreRunning;min;max;q1;median;q3;dataFrom;fail2;fail3;fail4;fail5;fail6");

            foreach (var dir in System.IO.Directory.GetDirectories(args[0]).OrderBy(path => {
                int val;
                int.TryParse(System.IO.Path.GetFileName(path).Substring(4), out val);
                return val;
            }))
            {

                // aggregate statistics per run
                var entries = GetEntriesForRun(dir).ToArray();

                // filter out the last entries that have failure
                // this are entries because the server connection have already been removed
                if (filterOutStartAndEnd)
                {
                    int lastNrOfFailures = 0;
                    for (int i = entries.Length - 1; i >= 0; i--)
                    {
                        if (entries[i].IsOK)
                            break;
                        else
                            lastNrOfFailures++;
                    }
                    entries = entries.SkipLast(lastNrOfFailures).ToArray();
                }

                long earliestWorkingTimestamp;
                long earliestWorkingTimestampForAllPods;
                if (entries.Where(e => e.IsOK).Count() == 0)
                {
                    earliestWorkingTimestamp = 0;
                    earliestWorkingTimestampForAllPods = 0;
                }
                else
                {
                    earliestWorkingTimestamp = entries.Where(e => e.IsOK).Min(e => e.Timestamp);
                    earliestWorkingTimestampForAllPods = entries.Where(e => e.IsOK).GroupBy(e => e.File)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.Timestamp).Min()).Values.Max();
                }

                if (filterOutStartAndEnd)
                {
                    // and only start metrics when all pods are running
                    entries = entries.Where(e => e.Timestamp > earliestWorkingTimestampForAllPods).ToArray();
                }

                long countFiles = entries.Select(e => e.File).Distinct().Count();
                long countAllFailure = entries.GroupBy(e => e.File).Where(g => g.All(e => !e.IsOK)).Count();

                long dataFrom = countFiles - countAllFailure;

                long count = entries.Length;
                long okCount = entries.Where(e => e.IsOK).Count();


                int[] consecutivefailures = new int[entries.Length+1];
                long sustainedFailureCount = 0;
                for (int i = 0; i < entries.Length; i++)
                {
                  //  if (!entries[i - 1].IsOK && entries[i].IsOK)
                    if (entries[i].IsOK)
                        sustainedFailureCount = 0;
                    else 
                        sustainedFailureCount++;

                    consecutivefailures[sustainedFailureCount]++;
                }
                if (sustainedFailureCount > 0)
                    consecutivefailures[sustainedFailureCount]++;


                long failedAtLeast2Times = consecutivefailures.Skip(2).Sum();
                long failedAtLeast3Times = consecutivefailures.Skip(3).Sum();
                long failedAtLeast4Times = consecutivefailures.Skip(4).Sum();
                long failedAtLeast5Times = consecutivefailures.Skip(5).Sum();
                long failedAtLeast6Times = consecutivefailures.Skip(6).Sum();

                var values = entries.Where(e => e.IsOK).Select(e => e.TotalTime).ToArray();

                string name = System.IO.Path.GetFileName(dir);

                double min = values.Length == 0 ? 0 : values.Min();
                double max = values.Length == 0 ? 0 : values.Max();
                double q1 = values.Length == 0 ? 0 : Percentile(values, 0.25);
                double median = values.Length == 0 ? 0 : Percentile(values, 0.5);
                double q3 = values.Length == 0 ? 0 : Percentile(values, 0.75);

                Console.WriteLine($"{name};{count};{okCount};{earliestWorkingTimestamp};{earliestWorkingTimestampForAllPods};{min.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{max.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{q1.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{median.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{q3.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{dataFrom};{failedAtLeast2Times};{failedAtLeast3Times};{failedAtLeast4Times};{failedAtLeast5Times};{failedAtLeast6Times}");
                //'   namelookup:  0.000032;
                //connect:  0.000996;
                //appconnect:  0.000000;
                //pretransfer:  0.001045;
                //redirect:  0.000000;
                //starttransfer:  0.001612;
                //total:  0.001644;
                //ok;'
            }

            Console.Read();

        }

        private static IEnumerable<Entry> GetEntriesForRun(string dir)
        {

            var clientDir = System.IO.Path.Combine(dir, "client");
            foreach (var file in System.IO.Directory.GetFiles(clientDir))
            {
                foreach (var line in System.IO.File.ReadLines(file))
                {
                    var parts = line.Split(';');
                    
                    long timestamp;
                    if (parts.Length >= 9 && long.TryParse(parts[8], out timestamp))
                    {
                        var totalTime = double.Parse(parts[6].Split(':')[1].Trim(), System.Globalization.CultureInfo.InvariantCulture);
                        var isOK = parts[7] == "ok";

                        yield return new Entry() { TotalTime = totalTime, IsOK = isOK, Timestamp = timestamp, File = file };
                    }
                    else
                    {
                        Console.Error.WriteLine("! Omitting line " + line + " from file " + file + " because it was unparsable");
                    }
                }
            }
        }
    }
}
