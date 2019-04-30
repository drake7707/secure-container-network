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
            public long Eth0RX { get; internal set; }
            public long Eth0TX { get; internal set; }
            public long Eth0RXPackets { get; internal set; }
            public long Eth0TXPackets { get; internal set; }
            public long VpnRX { get; internal set; }
            public long VpnTX { get; internal set; }
            public long VpnTXPackets { get; internal set; }
            public long VpnRXPackets { get; internal set; }
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

            List<IEnumerator<Entry>> allEntries = new List<IEnumerator<Entry>>();


            Console.WriteLine("name;eth_bytes_sent_rate;eth_bytes_received_rate;eth_max_bytes_sent;eth_max_bytes_received;eth_packets_sent_rate;eth_packets_received_rate;avg_time_between_packets;avg_eth_packet_size_sent;avg_eth_packet_size_received;control_bytes_sent_rate;control_bytes_received_rate;control_max_bytes_sent;control_max_bytes_received;control_packets_sent_rate;control_packets_received_rate;avg_control_packet_size_sent;avg_control_packet_size_received;vpn_bytes_sent_rate;vpn_bytes_received_rate;vpn_max_bytes_sent;vpn_max_bytes_received;vpn_packets_sent_rate;vpn_packets_received_rate;avg_vpn_packet_size_sent;avg_vpn_packet_size_received;control_overhead_sent;control_overhead_received");

            foreach (var dir in System.IO.Directory.GetDirectories(args[0]))
            {

                // aggregate statistics per run
                var entriesPerFile = GetEntriesForRun(dir).GroupBy(e => e.File).ToDictionary(g => g.Key, g => g.ToArray());

                List<long> times_between_packets = new List<long>();

                List<double> eth_sent_rates = new List<double>();
                List<double> eth_received_rates = new List<double>();
                List<double> eth_max_bytes_received = new List<double>();
                List<double> eth_max_bytes_sent = new List<double>();
                List<double> eth_sent_packet_rates = new List<double>();
                List<double> eth_received_packet_rates = new List<double>();

                
                List<double> eth_packet_sizes_sent = new List<double>();
                List<double> eth_packet_sizes_received = new List<double>();

                List<double> control_sent_rates = new List<double>();
                List<double> control_received_rates = new List<double>();
                List<double> control_max_bytes_received = new List<double>();
                List<double> control_max_bytes_sent = new List<double>();
                List<double> control_sent_packet_rates = new List<double>();
                List<double> control_received_packet_rates = new List<double>();

                List<double> control_packet_sizes_sent = new List<double>();
                List<double> control_packet_sizes_received = new List<double>();


                List<double> vpn_sent_rates = new List<double>();
                List<double> vpn_received_rates = new List<double>();
                List<double> vpn_max_bytes_received = new List<double>();
                List<double> vpn_max_bytes_sent = new List<double>();
                List<double> vpn_sent_packet_rates = new List<double>();
                List<double> vpn_received_packet_rates = new List<double>();

                List<double> vpn_packet_sizes_sent = new List<double>();
                List<double> vpn_packet_sizes_received = new List<double>();

                foreach (var pair in entriesPerFile)
                {
                    var entries = pair.Value;

                    {
                        var ethRX = entries[0].Eth0RX;
                        var ethTX = entries[0].Eth0TX;
                        var ethRXPackets = entries[0].Eth0RXPackets;
                        var ethTXPackets = entries[0].Eth0TXPackets;
                        var ethRXTimestamp = entries[0].Timestamp;
                        var ethTXTimestamp = entries[0].Timestamp;

                        var controlRX = entries[0].Eth0RX - entries[0].VpnRX;
                        var controlTX = entries[0].Eth0TX - entries[0].VpnTX;

                        var vpnRX = entries[0].VpnRX;
                        var vpnTX = entries[0].VpnTX;
                        var vpnRXPackets = entries[0].VpnRXPackets;
                        var vpnTXPackets = entries[0].VpnTXPackets;

                        for (int i = 1; i < entries.Length; i++)
                        {
                            if (entries[i].Eth0RXPackets > ethRXPackets)
                            {
                                times_between_packets.Add(entries[i].Timestamp - ethRXTimestamp);
                                eth_packet_sizes_received.Add((entries[i].Eth0RX - ethRX) / (double)(entries[i].Eth0RXPackets - ethRXPackets));
                                control_packet_sizes_received.Add((entries[i].Eth0RX - entries[i].VpnRX - controlRX) / (double)(entries[i].Eth0RXPackets - ethRXPackets));

                                ethRXTimestamp = entries[i].Timestamp;
                                ethRX = entries[i].Eth0RX;
                                ethRXPackets = entries[i].Eth0RXPackets;

                                controlRX = entries[i].Eth0RX - entries[i].VpnRX;
                            }

                            if (entries[i].Eth0TXPackets > ethTXPackets)
                            {
                                times_between_packets.Add(entries[i].Timestamp - ethTXTimestamp);
                                eth_packet_sizes_sent.Add((entries[i].Eth0TX - ethTX) / (double)(entries[i].Eth0TXPackets - ethTXPackets));
                                control_packet_sizes_sent.Add((entries[i].Eth0TX - entries[i].VpnTX - controlTX) / (double)(entries[i].Eth0TXPackets - ethTXPackets));

                                ethTXTimestamp = entries[i].Timestamp;
                                ethTX = entries[i].Eth0TX;
                                ethTXPackets = entries[i].Eth0TXPackets;

                                controlTX = entries[i].Eth0TX - entries[i].VpnTX;
                            }

                            if (entries[i].VpnRXPackets > vpnRXPackets)
                            {
                                vpn_packet_sizes_received.Add((entries[i].VpnRX - vpnRX) / (double)(entries[i].VpnRXPackets - vpnRXPackets));
                                vpnRX = entries[i].VpnRX;
                                vpnRXPackets = entries[i].VpnRXPackets;
                            }

                            if (entries[i].VpnTXPackets > vpnTXPackets)
                            {
                                vpn_packet_sizes_sent.Add((entries[i].VpnTX - vpnTX) / (double)(entries[i].VpnTXPackets - vpnTXPackets));
                                vpnTX = entries[i].VpnTX;
                                vpnTXPackets = entries[i].VpnTXPackets;
                            }

                        }
                    }

                    var period = entries.Last().Timestamp - entries.First().Timestamp;
                    if (period > 0)
                    {
                        var eth_total_bytes_sent = entries.Last().Eth0TX;
                        var eth_total_bytes_received = entries.Last().Eth0RX;

                        var eth_total_packet_sent = entries.Last().Eth0TXPackets;
                        var eth_total_packet_received = entries.Last().Eth0RXPackets;

                        var eth_bytes_sent_rate = (double)eth_total_bytes_sent / period;
                        var eth_bytes_received_rate = (double)eth_total_bytes_received / period;

                        var eth_packet_sent_rate = (double)eth_total_packet_sent / period;
                        var eth_packet_received_rate = (double)eth_total_packet_received / period;

                        eth_sent_rates.Add(eth_bytes_sent_rate);
                        eth_received_rates.Add(eth_bytes_received_rate);

                        eth_sent_packet_rates.Add(eth_packet_sent_rate);
                        eth_received_packet_rates.Add(eth_packet_received_rate);

                        var control_total_bytes_sent = entries.Last().Eth0TX - entries.Last().VpnTX;
                        var control_total_bytes_received = entries.Last().Eth0RX - entries.Last().VpnRX;

                        var control_total_packet_sent = entries.Last().Eth0TXPackets - entries.Last().VpnTXPackets;
                        var control_total_packet_received = entries.Last().Eth0RXPackets - entries.Last().VpnRXPackets;

                        var control_bytes_sent_rate = (double)control_total_bytes_sent / period;
                        var control_bytes_received_rate = (double)control_total_bytes_received / period;
                            
                        var control_packet_sent_rate = (double)control_total_packet_sent / period;
                        var control_packet_received_rate = (double)control_total_packet_received / period;


                        control_sent_rates.Add(control_bytes_sent_rate);
                        control_received_rates.Add(control_bytes_received_rate);

                        control_sent_packet_rates.Add(control_packet_sent_rate);
                        control_received_packet_rates.Add(control_packet_received_rate);

                        var vpn_total_bytes_sent = entries.Last().VpnTX;
                        var vpn_total_bytes_received = entries.Last().VpnRX;

                        var vpn_total_packet_sent = entries.Last().VpnTXPackets;
                        var vpn_total_packet_received = entries.Last().VpnRXPackets;

                        var vpn_bytes_sent_rate = (double)vpn_total_bytes_sent / period;
                        var vpn_bytes_received_rate = (double)vpn_total_bytes_received / period;

                        var vpn_packet_sent_rate = (double)vpn_total_packet_sent / period;
                        var vpn_packet_received_rate = (double)vpn_total_packet_received / period;

                        vpn_sent_rates.Add(vpn_bytes_sent_rate);
                        vpn_received_rates.Add(vpn_bytes_received_rate);

                        vpn_sent_packet_rates.Add(vpn_packet_sent_rate);
                        vpn_received_packet_rates.Add(vpn_packet_received_rate);
                    }
                    else
                    {
                        eth_sent_rates.Add(0);
                        eth_received_rates.Add(0);

                        eth_sent_packet_rates.Add(0);
                        eth_received_packet_rates.Add(0);

                        eth_max_bytes_sent.Add(entries.Last().Eth0RX);
                        eth_max_bytes_received.Add(entries.Last().Eth0TX);

                        control_sent_rates.Add(0);
                        control_received_rates.Add(0);

                        control_sent_packet_rates.Add(0);
                        control_received_packet_rates.Add(0);

                        vpn_sent_rates.Add(0);
                        vpn_received_rates.Add(0);

                        vpn_sent_packet_rates.Add(0);
                        vpn_received_packet_rates.Add(0);

                        vpn_max_bytes_sent.Add(entries.Last().VpnRX);
                        vpn_max_bytes_received.Add(entries.Last().VpnTX);
                    }

                    eth_max_bytes_sent.Add(entries.Last().Eth0TX);
                    eth_max_bytes_received.Add(entries.Last().Eth0RX);

                    control_max_bytes_sent.Add(entries.Last().Eth0TX - entries.Last().VpnTX);
                    control_max_bytes_received.Add(entries.Last().Eth0RX - entries.Last().VpnRX);

                    vpn_max_bytes_sent.Add(entries.Last().VpnTX);
                    vpn_max_bytes_received.Add(entries.Last().VpnRX);
                }


                var name = System.IO.Path.GetFileName(dir);

                var avg_time_between_packets = times_between_packets.Count == 0 ? 0 : times_between_packets.Average();

                var avg_eth_bytes_sent_rate = eth_sent_rates.Average();
                var avg_eth_bytes_received_rate = eth_received_rates.Average();

                var avg_eth_packets_sent_rate = eth_sent_packet_rates.Average();
                var avg_eth_packets_received_rate = eth_received_packet_rates.Average();

                var avg_eth_max_bytes_sent = eth_max_bytes_sent.Average();
                var avg_eth_max_bytes_received = eth_max_bytes_received.Average();

                var avg_eth_packet_size_sent = eth_packet_sizes_sent.Count == 0 ? 0 : eth_packet_sizes_sent.Average();
                var avg_eth_packet_size_received = eth_packet_sizes_received.Count == 0 ? 0 : eth_packet_sizes_received.Average();


                var avg_control_bytes_sent_rate = control_sent_rates.Average();
                var avg_control_bytes_received_rate = control_received_rates.Average();

                var avg_control_packets_sent_rate = control_sent_packet_rates.Average();
                var avg_control_packets_received_rate = control_received_packet_rates.Average();

                var avg_control_max_bytes_sent = control_max_bytes_sent.Average();
                var avg_control_max_bytes_received = control_max_bytes_received.Average();

                var avg_control_packet_size_sent = control_packet_sizes_sent.Count == 0 ? 0 : control_packet_sizes_sent.Average();
                var avg_control_packet_size_received = control_packet_sizes_received.Count == 0 ? 0 : control_packet_sizes_received.Average();

                var avg_vpn_bytes_sent_rate = vpn_sent_rates.Average();
                var avg_vpn_bytes_received_rate = vpn_received_rates.Average();

                var avg_vpn_packets_sent_rate = vpn_sent_packet_rates.Average();
                var avg_vpn_packets_received_rate = vpn_received_packet_rates.Average();

                var avg_vpn_max_bytes_sent = vpn_max_bytes_sent.Average();
                var avg_vpn_max_bytes_received = vpn_max_bytes_received.Average();

                var avg_vpn_packet_size_sent = vpn_packet_sizes_sent.Count == 0 ? 0 : vpn_packet_sizes_sent.Average();
                var avg_vpn_packet_size_received = vpn_packet_sizes_received.Count == 0 ? 0 : vpn_packet_sizes_received.Average();

                var control_overhead_rx = (avg_control_max_bytes_sent / avg_eth_max_bytes_sent);
                var control_overhead_tx = (avg_control_max_bytes_received / avg_eth_max_bytes_received);

                Console.WriteLine($"{name};{Fmt(avg_eth_bytes_sent_rate)};{Fmt(avg_eth_bytes_received_rate)};{Fmt(avg_eth_max_bytes_sent)};{Fmt(avg_eth_max_bytes_received)};{Fmt(avg_eth_packets_sent_rate)};{Fmt(avg_eth_packets_received_rate)};{Fmt(avg_time_between_packets)};{Fmt(avg_eth_packet_size_sent)};{Fmt(avg_eth_packet_size_received)};{Fmt(avg_control_bytes_sent_rate)};{Fmt(avg_control_bytes_received_rate)};{Fmt(avg_control_max_bytes_sent)};{Fmt(avg_control_max_bytes_received)};{Fmt(avg_control_packets_sent_rate)};{Fmt(avg_control_packets_received_rate)};{Fmt(avg_control_packet_size_sent)};{Fmt(avg_control_packet_size_received)};{Fmt(avg_vpn_bytes_sent_rate)};{Fmt(avg_vpn_bytes_received_rate)};{Fmt(avg_vpn_max_bytes_sent)};{Fmt(avg_vpn_max_bytes_received)};{Fmt(avg_vpn_packets_sent_rate)};{Fmt(avg_vpn_packets_received_rate)};{Fmt(avg_vpn_packet_size_sent)};{Fmt(avg_vpn_packet_size_received)};{Fmt(control_overhead_tx)};{Fmt(control_overhead_rx)}");
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
                    var parts = line.Split(';');

                    long timestamp;
                    if (long.TryParse(parts[0], out timestamp))
                    {
                        long eth0RX = int.Parse(parts[1]);
                        long eth0TX = int.Parse(parts[2]);

                        long eth0RXPackets = int.Parse(parts[3]);
                        long eth0TXPackets = int.Parse(parts[4]);

                        long vpnRX = int.Parse(parts[5]);
                        long vpnTX = int.Parse(parts[6]);

                        long vpnRXPackets = int.Parse(parts[7]);
                        long vpnTXPackets = int.Parse(parts[8]);

                        yield return new Entry() { File = file, Timestamp = timestamp, Eth0RX = eth0RX, Eth0TX = eth0TX, Eth0RXPackets = eth0RXPackets, Eth0TXPackets = eth0TXPackets, VpnRX = vpnRX, VpnTX = vpnTX, VpnRXPackets = vpnRXPackets, VpnTXPackets = vpnTXPackets };
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
