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
            public long Timestamp { get; set; }
            public string File { get; internal set; }
            //user_time;kernel_time;child_user_time;child_kernel_time;vm_size;resident_size;shared_size
            public long UserTime { get; set; }
            public long KernelTime { get; set; }
            public long ChildUserTime { get; set; }
            public long ChildKernelTime { get; set; }
            public long MemVMSize { get; set; }
            public long MemResidentSize { get; set; }
            public long MemSharedSize { get; set; }

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


            Console.WriteLine("name;sample_size;timestamp;user_time;kernel_time;child_user_time;child_kernel_time;total_time;vm_size;resident_size;shared_size");

            foreach (var dir in System.IO.Directory.GetDirectories(args[0]))
            {

                // aggregate statistics per run
                var entriesPerFile = GetEntriesForRun(dir).GroupBy(e => e.File).ToDictionary(g => g.Key, g => g.ToArray());



                var user_times = new Dictionary<long, List<long>>();
                var kernel_times = new Dictionary<long, List<long>>();
                var child_user_times = new Dictionary<long, List<long>>();
                var child_kernel_times = new Dictionary<long, List<long>>();
                var vm_sizes = new Dictionary<long, List<long>>();
                var resident_sizes = new Dictionary<long, List<long>>();
                var shared_sizes = new Dictionary<long, List<long>>();

                foreach (var pair in entriesPerFile)
                {
                    var entries = pair.Value;

                    var earliestTimestamp = entries.OrderBy(e => e.Timestamp).Select(e => e.Timestamp).First();

                    foreach (var entry in entries)
                    {
                        if (!user_times.ContainsKey(entry.Timestamp - earliestTimestamp)) user_times[entry.Timestamp - earliestTimestamp] = new List<long>();
                        if (!kernel_times.ContainsKey(entry.Timestamp - earliestTimestamp)) kernel_times[entry.Timestamp - earliestTimestamp] = new List<long>();
                        if (!child_user_times.ContainsKey(entry.Timestamp - earliestTimestamp)) child_user_times[entry.Timestamp - earliestTimestamp] = new List<long>();
                        if (!child_kernel_times.ContainsKey(entry.Timestamp - earliestTimestamp)) child_kernel_times[entry.Timestamp - earliestTimestamp] = new List<long>();
                        if (!vm_sizes.ContainsKey(entry.Timestamp - earliestTimestamp)) vm_sizes[entry.Timestamp - earliestTimestamp] = new List<long>();
                        if (!resident_sizes.ContainsKey(entry.Timestamp - earliestTimestamp)) resident_sizes[entry.Timestamp - earliestTimestamp] = new List<long>();
                        if (!shared_sizes.ContainsKey(entry.Timestamp - earliestTimestamp)) shared_sizes[entry.Timestamp - earliestTimestamp] = new List<long>();

                        user_times[entry.Timestamp - earliestTimestamp].Add(entry.UserTime);
                        kernel_times[entry.Timestamp - earliestTimestamp].Add(entry.KernelTime);
                        child_user_times[entry.Timestamp - earliestTimestamp].Add(entry.ChildUserTime);
                        child_kernel_times[entry.Timestamp - earliestTimestamp].Add(entry.ChildKernelTime);
                        vm_sizes[entry.Timestamp - earliestTimestamp].Add(entry.MemVMSize);
                        resident_sizes[entry.Timestamp - earliestTimestamp].Add(entry.MemResidentSize);
                        shared_sizes[entry.Timestamp - earliestTimestamp].Add(entry.MemSharedSize);
                    }
                }

                string name = System.IO.Path.GetFileName(dir);

                var timestamps = user_times.Keys.OrderBy(t => t).ToArray();
                if (timestamps.Length > 0)
                {
                    
                    foreach (var ts in timestamps)
                    {


                        var avg_user_time = user_times[ts].Average();
                        var avg_kernel_time = kernel_times[ts].Average();

                        var avg_child_user_time = child_user_times[ts].Average();
                        var avg_child_kernel_time = child_kernel_times[ts].Average();
                        var avg_vm_size = vm_sizes[ts].Average();
                        var avg_resident_size = resident_sizes[ts].Average();
                        var avg_shared_size = shared_sizes[ts].Average();

                        var sample_size = user_times[ts].Count;
                        var total_avg_time = avg_user_time + avg_kernel_time + avg_child_user_time + avg_child_kernel_time;

                        Console.WriteLine($"{name};{sample_size};{ts};{avg_user_time};{avg_kernel_time};{avg_child_user_time};{avg_child_kernel_time};{total_avg_time};{avg_vm_size};{avg_resident_size};{avg_shared_size}"); 
                    }
                }



            }

            Console.Read();
        }

        private static string Fmt(double val)
        {
            return val.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);
        }

        private static IEnumerable<Entry> GetEntriesForRun(string dir)
        {

            var clientDir = System.IO.Path.Combine(dir, "client");
            foreach (var file in System.IO.Directory.GetFiles(clientDir))
            {
                foreach (var line in System.IO.File.ReadLines(file))
                {
                    var parts = line.Split(' ');

                    long timestamp;
                    if (long.TryParse(parts[0], out timestamp) && parts.Length > 7)
                    {

                        long userTime = int.Parse(parts[1]);
                        long kernelTime = int.Parse(parts[2]);

                        long childUserTime = int.Parse(parts[3]);
                        long childKernelTime = int.Parse(parts[4]);

                        long vmSize = int.Parse(parts[5]);
                        long residentSize = int.Parse(parts[6]);
                        long sharedSize = int.Parse(parts[7]);


                        yield return new Entry() { File = file, Timestamp = timestamp, UserTime = userTime, KernelTime = kernelTime, ChildUserTime = childUserTime, ChildKernelTime = childKernelTime, MemVMSize = vmSize, MemResidentSize = residentSize, MemSharedSize = sharedSize };
                    }
                }
            }
        }

        // Return the standard deviation of an array of Doubles.
        //
        // If the second argument is True, evaluate as a sample.
        // If the second argument is False, evaluate as a population.
        public static double StdDev(IEnumerable<double> values,
            bool as_sample)
        {
            // Get the mean.
            double mean = values.Sum() / values.Count();

            // Get the sum of the squares of the differences
            // between the values and the mean.
            var squares_query =
                from double value in values
                select (value - mean) * (value - mean);
            double sum_of_squares = squares_query.Sum();

            if (as_sample)
            {
                return Math.Sqrt(sum_of_squares / (values.Count() - 1));
            }
            else
            {
                return Math.Sqrt(sum_of_squares / values.Count());
            }
        }
    }
}
